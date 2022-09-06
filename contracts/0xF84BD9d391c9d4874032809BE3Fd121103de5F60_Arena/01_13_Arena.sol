// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.15;

// contract where staked matador nfts are stored
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IGenesis.sol";

contract Arena is Ownable, IERC721Receiver {
    
    using EnumerableSet for EnumerableSet.UintSet;

    constructor() {
        Genesis = 0x810FeDb4a6927D02A6427f7441F6110d7A1096d5;
        GenesisInterface = IGenesis(0x810FeDb4a6927D02A6427f7441F6110d7A1096d5);
    }

    address public Genesis;
    IGenesis public GenesisInterface;
    address public BullRunGame; // BullRun game contract
    mapping(uint16 => address) private OriginalOwner; // tokID => wallet of staker

    EnumerableSet.UintSet private matadorIds;

    event MatadorReceived (address indexed _originalOwner, uint16 _id);
    event MatadorReturned (address indexed _returnee, uint16 _id);
    event BullThiefSelected (address indexed _thief);

    modifier onlyBullRunGame() {
        require(BullRunGame != address(0) , "BullRunGame has not been set yet");
        require(msg.sender == BullRunGame , "Only the BullRun game contract can call this");
        _;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setBullRunGameContract(address _bullRun) external onlyOwner {
        BullRunGame = _bullRun;
    }

    // number of matadors in this contract
    function matadorCount() public view returns (uint16) {
        return uint16(matadorIds.length());
    }

    // for Matador owners who are staking
    function receiveMatador(address _originalOwner, uint16 _id) external onlyBullRunGame() {
        OriginalOwner[_id] = _originalOwner;
        matadorIds.add(_id);
        emit MatadorReceived(_originalOwner, _id);
    }

    // for Matador owners who are unstaking
    function returnMatadorToOwner(address _returnee, uint16 _id) external onlyBullRunGame() {
        require(_returnee == OriginalOwner[_id], "Matador does not belong to passed returnee");
        IERC721(Genesis).safeTransferFrom(address(this), _returnee, _id);
        delete OriginalOwner[_id];
        matadorIds.remove(_id);
        emit MatadorReturned(_returnee, _id);
    }

    // return staker address of a Matador ID
    function getMatadorOwner(uint16 _id) external view returns (address) {
        return OriginalOwner[_id];
    }

    // if a Bull unstakes, and is selected to be stolen, choose a random matador staker to receive 
    function selectRandomMatadorOwnerToReceiveStolenBull(uint256 seed) external onlyBullRunGame() returns (address) {
        uint256 bucket = (seed & 0xFFFFFFFF) % matadorIds.length();
        address thief = OriginalOwner[uint16(matadorIds.at(bucket))];
        emit BullThiefSelected(thief);
        return thief;
    }

    function setGenesis(address _genesis) external onlyOwner {
        Genesis = _genesis;
        GenesisInterface = IGenesis(_genesis);
    }
}