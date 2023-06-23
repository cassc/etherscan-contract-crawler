/**
 *Submitted for verification at Etherscan.io on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract TempusPrizeHandler is Ownable{

    mapping(address => uint256) public gamePrizeTotal;
    bool private withdrawOpen = false;

    //Admin Functions
    function clearRewards(address _wallet) external onlyOwner{
        gamePrizeTotal[_wallet] = 0;
    }

    function withdrawOpenToggle() external onlyOwner{
        withdrawOpen = !withdrawOpen;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    //Admin Prize Handler
    function uploadPrizeWinners(address[] calldata _winners, uint256[] calldata _prizeTotals) external onlyOwner {
        require(_winners.length > 0, "Wrong amount of winner addresses");
        require(_prizeTotals.length > 0, "Wrong amount of prizes");
        require(_winners.length == _prizeTotals.length, "All winners need a prize amount");

        for(uint256 i = 0; i < _winners.length; i++){
            gamePrizeTotal[_winners[i]] = gamePrizeTotal[_winners[i]] + _prizeTotals[i]; 
        }
    }

    //Add eth amount to contract prize pool
    function topUpContract() public payable onlyOwner {
        require(msg.value > .0 ether);
    }

    event Donation(
        address _sender,
        uint256 _donation
    );

    function donateToContract() public payable {
        require(msg.value > .0 ether);
        emit Donation(msg.sender, msg.value);
    }

    //Prize section
    function checkWinnings() external view returns(uint256){
        return gamePrizeTotal[msg.sender];
    }

    function withdrawPrizeMoney() external {
        require(withdrawOpen == true, "Withdraw currently paused");
        require(gamePrizeTotal[msg.sender] > 0, "User has no prize money to claim");
        uint256 _prizeWinnings = gamePrizeTotal[msg.sender];
        payable(msg.sender).transfer(_prizeWinnings);

        clearClaimedWinnings();
    }

    function clearClaimedWinnings() internal{
        gamePrizeTotal[msg.sender] = 0;
    }
}