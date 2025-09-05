// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// 接口
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SimpleERC20 is IERC20{
    // token metadata 代币名称
    string public name;

    // token metadata 代币符号
    string public symbol;

    // token metadata 小数位数
    uint8 public immutable decimals;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address public owner;

    // 修饰器，只允许合约拥有者执行
    modifier onlyOwner(){
        require(msg.sender == owner, "SimpleERC20: caller is not the owner");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint8 _decimals){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        owner = msg.sender;
    }

    // 转账逻辑
    function _transfer(address from, address to, uint256 amount) internal{
        require(from != address(0), "SimpleERC20: transfer from the zero address");
        require(to != address(0), "SimpleERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "SimpleERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    // 授权逻辑
    function _approve(address owner, address spender, uint256 amount) internal{
        require(owner != address(0), "SimpleERC20: approve from the zero address");
        require(spender != address(0), "SimpleERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // 代币总量
    function totalSupply() external view override returns (uint256){
        return _totalSupply;
    }

    // 账号拥有代币数量
    function balanceOf(address account) external view override returns (uint256){
        return _balances[account];
    }

    function allowance(address owner, address spender) external view override returns (uint256){
        return _allowances[owner][spender];
    }

    // 转账
    function transfer(address to, uint256 amount) external override returns (bool){
        _transfer(msg.sender, to, amount);
        return true;
    }

    // 授权
    function approve(address spender, uint256 amount) external override returns (bool){
        _approve(msg.sender, spender, amount);
        return true;
    }

    // 代扣转账
    function transferFrom(address from, address to, uint256 amount) external override returns (bool){
        uint256 currentAllowance =  _allowances[from][msg.sender];
        require(currentAllowance >= amount, "SimpleERC20: transfer amount exceeds allowance");
        _approve(from, msg.sender, currentAllowance - amount);
        _transfer(from, to, amount);
        return true;
    }

    // 增发代币
    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        require(to != address(0), "SimpleERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
        return true;
    }

    // 修改合约所有者
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "SimpleERC20: new owner is the zero address");
        owner = newOwner;
    }
}