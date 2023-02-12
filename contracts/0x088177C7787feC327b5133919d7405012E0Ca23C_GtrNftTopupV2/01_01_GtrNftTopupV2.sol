// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor() { _paused = false; }
    function paused() public view virtual returns (bool) { return _paused; }
    modifier whenNotPaused() { require(!paused(), "Pausable: paused"); _; }
    modifier whenPaused() { require(paused(), "Pausable: not paused"); _; }
    function _pause() internal virtual whenNotPaused { _paused = true; emit Paused(_msgSender()); }
    function _unpause() internal virtual whenPaused { _paused = false; emit Unpaused(_msgSender()); }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _transferOwnership(_msgSender()); }
    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() { require(owner() == _msgSender(), "Ownable: caller is not the owner"); _; }
    function renounceOwnership() public virtual onlyOwner { _transferOwnership(address(0)); }
    function transferOwnership(address newOwner) public virtual onlyOwner { require(newOwner != address(0), "Ownable: new owner is the zero address"); _transferOwnership(newOwner); }
    function _transferOwnership(address newOwner) internal virtual {address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner); }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
}

contract GtrNftTopupV2 is Ownable, Pausable {

    mapping(IERC20 => bool) public _validTokenContracts;
    mapping(IERC721 => bool) public _validNftContracts;
    address public _depositAddress;
    uint256 public _depositTaxPercent;
    uint256 public _depositTaxPercentDivisor;

    event DepositRequested(address sender, address nftContract, uint256 nftId, address tokenContract, uint8 tokenDecimals, uint256 depositAmount, uint taxAmount);
    event WithdrawalRequested(address sender, address nftContract, uint256 nftId, uint256 amount);
    
    constructor() {
        //validate stablecoins for deposit
        _validTokenContracts[IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7)] = true; //usdt mainnet
        _validTokenContracts[IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53)] = true; //busd mainnet
        _validTokenContracts[IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48)] = true; //usdc mainnet

        //validate existing GTR NFT contracts
        _validNftContracts[IERC721(0x472B932cc83678f75A409326b71c7FCB16081Dd3)] = true; //diamond
        _validNftContracts[IERC721(0xdAeC66BD252768DB641E8F51255260762708ACf4)] = true; //gold
        _validNftContracts[IERC721(0x837204F046fF7F2a6E50cC4aec6aDc85D20a2A72)] = true; //silver

        //set deposit settings
        _depositAddress = 0x628789179aA833f3D8Aa319b3a3604991a682c2f;
        _depositTaxPercent = 5;
        _depositTaxPercentDivisor = 100;
    }

    function deposit(IERC721 nftContract, uint256 nftId, IERC20 tokenContract, uint256 amount) external whenNotPaused {
        //validate tx
        require(_validNftContracts[nftContract] == true, "NFT_INVALID");
        require(nftId <= nftContract.totalSupply(), "NFT_INVALID");
        require(nftContract.ownerOf(nftId) != address(0), "NFT_INVALID");
        require(_validTokenContracts[tokenContract] == true, "ASSET_INVALID");
        require(amount > 0, "AMOUNT_INVALID");

        //transfer funds
        require(tokenContract.balanceOf(msg.sender) >= amount, "BALANCE_INSUFFICIENT");
        require(tokenContract.allowance(msg.sender, address(this)) >= amount, "ALLOWANCE_INSUFFICIENT");
        (bool success, bytes memory data) = address(tokenContract).call(abi.encodeWithSelector(IERC20.transferFrom.selector, msg.sender, _depositAddress, amount)); 
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC20_TRANSFER_FAILED");

        //emit event
        uint256 taxAmount = (_depositTaxPercent > 0 && _depositTaxPercentDivisor > 0) ? (amount * _depositTaxPercent / _depositTaxPercentDivisor) : 0;
        uint256 depositAmount = amount - taxAmount;
        emit DepositRequested(msg.sender, address(nftContract), nftId, address(tokenContract), tokenContract.decimals(), depositAmount, taxAmount);
    }

    function withdraw(IERC721 nftContract, uint256 nftId, uint256 amount) external whenNotPaused {
        require(_validNftContracts[nftContract] == true, "NFT_INVALID");
        require(nftId <= nftContract.totalSupply(), "NFT_INVALID");
        require(nftContract.ownerOf(nftId) == msg.sender, "NOT_ALLOWED");

        //emit event
        emit WithdrawalRequested(msg.sender, address(nftContract), nftId, amount);
    }

    //admin functions
    function setValidTokenContractStatus(IERC20 contractAddress, bool status) external onlyOwner {
        _validTokenContracts[contractAddress] = status;
    }

    function setValidNftContractStatus(IERC721 contractAddress, bool status) external onlyOwner {
        _validNftContracts[contractAddress] = status;
    }

    function setDepositWalletAddress(address to) external onlyOwner {
        _depositAddress = to;
    }

    function setDepositTaxPercent(uint256 amount, uint256 divisor) external onlyOwner {
        _depositTaxPercent = amount;
        _depositTaxPercentDivisor = divisor;
    }

    //pausable implementation
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    //default withdrawal functions
    function withdrawToken(IERC20 token, uint256 amount, address to) external onlyOwner {
        if (address(token) == address(0)) {
            (bool success, ) = to.call{value: (amount == 0 ? address(this).balance : amount)}(new bytes(0)); 
            require(success, "NATIVE_TRANSFER_FAILED");
        } else {
            (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, (amount == 0 ? token.balanceOf(address(this)) : amount))); 
            require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC20_TRANSFER_FAILED");
        }
    }

    receive() external payable {}
}