/**
 *Submitted for verification at Etherscan.io on 2023-05-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity 0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function deposit() external payable;
    function withdraw(uint wad) external;
}

pragma solidity >=0.6.0;

library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }
}


pragma solidity 0.8.7;

interface WewePresaleNftInterface {
    function balanceOf(address owner) external view returns (uint256 balance);
    function mintPresaleNFT(address to) external;
}

contract WeweImplementation is Ownable {
    address weweErc20;
    WewePresaleNftInterface wewePresaleNFTContract;

    function setWeweImplementation(address erc20Address_, address nftAddress_) public onlyOwner {
        weweErc20 = erc20Address_;
        wewePresaleNFTContract = WewePresaleNftInterface(nftAddress_);
    }

    function getWewePresaleNftBalance(address address_) internal view returns (uint256) {
        return wewePresaleNFTContract.balanceOf(address_);
    }

    function mintPresaleNFT(address address_) internal {
        wewePresaleNFTContract.mintPresaleNFT(address_);
    }

}

pragma solidity 0.8.7;

contract WewePresaleRegistrar is WeweImplementation {
    
    constructor()  {}

    bool public presaleActive = true;
    bool public claimActive = false;

    uint256 totalSupply = 420690000000 * 10 ** 18;
    uint256 presalePercent = 22;
    uint256 presaleSupply = totalSupply * presalePercent / 100;

    mapping(address => uint256) private investments;
    mapping(address => bool) private claimed;
    uint256 totalPool;

    function invest() public payable {
        require(msg.value > 0, "Value is zero");
        require(presaleActive, "Presale is not active");
        investments[msg.sender] = investments[msg.sender] + msg.value;
        totalPool = totalPool + msg.value;

        if(getWewePresaleNftBalance(msg.sender) == 0) {
            mintPresaleNFT(msg.sender);
        }
    }

    function claim() public {
        require(claimActive, "Claim is not active");
        require(!claimed[msg.sender], "Already claimed by address");
        uint256 amount = amountClaimable(msg.sender);
        require(amount > 0, "Amount is zero");
        TransferHelper.safeTransfer(weweErc20, msg.sender, amount);
        claimed[msg.sender] = true;
    }

    function amountClaimable(address address_) public view returns (uint256) {
        uint256 amount = (presaleSupply * investments[address_]) / totalPool;
        return amount;
    }

    function isClaimed(address address_) public  view returns (bool) {
        return claimed[address_];
    }

    function getAddressInvestment(address address_) public view returns (uint256) {
        return investments[address_];
    }

    function getTotalPool() public view returns (uint256) {
        return totalPool;
    }

    function flipPresaleActive() public onlyOwner {
        presaleActive = !presaleActive;
    }

    function flipClaimActive() public onlyOwner {
        claimActive = !claimActive;
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        payable(to).transfer(amount);
    }

    function withdrawErc20(address to, uint256 amount, address token_) public onlyOwner {
        IERC20 erc20 = IERC20(token_);
        require(amount <= erc20.balanceOf(address(this)), "Amount exceeds balance.");
        TransferHelper.safeTransfer(token_, to, amount);
    }

    function setSupplyInfo(uint256 totalSupply_, uint256 presalePercent_) public onlyOwner {
        totalSupply = totalSupply_;
        presalePercent = presalePercent_;
    }

}