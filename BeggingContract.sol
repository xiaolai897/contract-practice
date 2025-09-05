// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract BeggingContract is Ownable, ReentrancyGuard {
    // 累计捐赠金额
    mapping ( address => uint256 ) private donations;

    // 存储捐赠地址，实现排行榜
    address[] private donors;
    mapping (address => bool) private hasDonatedBefore;

    // 时间限制
    bool public timeLimitEnabled = false;
    uint256 public donateStart;
    uint256 public donateEnd;

    // 事件
    event Donation(address indexed donor, uint256 amount);
    event Withdraw(address indexed owner, uint256 amount);

    constructor() Ownable(msg.sender) {}

    // 规定时间段内才可捐赠
    modifier withinTimeWindow(){
        if (timeLimitEnabled) {
            require(block.timestamp >= donateStart && block.timestamp <= donateEnd, "Not in donation period");
        }
        _;
    }

    // 向合约捐赠 ETH
    function donate() external payable withinTimeWindow {
        require(msg.value >0, "Must send ETH");

        if (!hasDonatedBefore[msg.sender]) {
            donors.push(msg.sender);
            hasDonatedBefore[msg.sender] = true;
        }

        donations[msg.sender] += msg.value;
        emit Donation(msg.sender, msg.value);
    }

    // 查询某个地址累计捐赠金额
    function getDonation(address donor) external view returns (uint256) {
        return donations[donor];
    }

    // 提取所有资金，仅限于owner
    function withdraw() external onlyOwner nonReentrant {
        uint256 bal = address(this).balance;
        require(bal >0, "No funds");

        payable(owner()).transfer(bal);
        emit Withdraw(owner(), bal);
    }

    // 查看合约余额
    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // 获取捐赠者数量
    function donorCount() external view returns (uint256) {
        return donors.length;
    }

    // 获取排行榜前3名

    function getTopDonors() external view returns (address[] memory topAddrs, uint256[] memory topAmounts) {
        uint256 total = donors.length;
        if (total == 0){
            return (new address[](3) , new uint256[](3) );
        }

        uint256 topN = total < 3 ? total : 3;
        topAddrs = new address[](topN);
        topAmounts = new uint256[](topN);

        for (uint256 i = 0; i < total; i++) {
            address donor = donors[i];
            uint256 amount = donations[donor];

            for (uint256 j = 0; j < topN; j++) {
                if (amount > topAmounts[j]) {
                    for (uint256 k = topN - 1; k > j; k--) {
                        topAmounts[k] = topAmounts[k - 1];
                        topAddrs[k] = topAddrs[k - 1];
                    }
                    topAmounts[j] = amount;
                    topAddrs[j] = donor;
                    break;
                }
            }
        }
    }

    // 是否启用时间限制仅限owner
    function setTimeLimitEnabled(bool enable) external onlyOwner {
        timeLimitEnabled = enable;
    }

    // 设置捐赠时间窗口仅限owner
    function setTimeWindow(uint256 start, uint256 end) external onlyOwner {
        require(start < end, "start < end required");
        donateStart = start;
        donateEnd = end;
    }

    // 根据下标获取捐赠者地址
    function donorAtIndex(uint256 index) external view returns (address) {
        require(index < donors.length, "Index out of range");
        return donors[index];
    }
}