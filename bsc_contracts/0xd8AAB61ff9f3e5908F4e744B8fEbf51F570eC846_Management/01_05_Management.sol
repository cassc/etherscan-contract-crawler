// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IManagement.sol";
import "./interfaces/IRandomService.sol";

contract Management is IManagement, Ownable {
    // Address of Treasury that receives fee and payments
    address public treasury;

    // Address of Verifier to verify signatures
    address public verifier;

    // Address that has an authority to mint MicrophoneNFT and ruby
    address public minter;

    // Address of microphoneNFT contract
    address public microphoneNFT;

    // Address of lootBox contract
    address public lootBox;

    // Address of breeding contract
    address public breeding;

    // Address of ruby contract
    address public ruby;

    // BUSD token address
    address public busd;

    // A map list of used signatures - keccak256(signature) => bytes32
    mapping(bytes32 => bool) public prevSigns;

    // Random generator service
    IRegistry public randomService;

    modifier AddressZero(address _addr) {
        require(_addr != address(0), "Set address to zero");
        _;
    }

    constructor(
        address _treasury,
        address _verifier,
        address _minter,
        address _randomService
    ) {
        treasury = _treasury;
        verifier = _verifier;
        minter = _minter;
        randomService = IRegistry(_randomService);
    }

    function admin() external view returns (address) {
        return owner();
    }

    /**
       @notice Change new address of Treasury
       @dev    Caller must be Owner
       @param _newTreasury Address of new Treasury
     */
    function updateTreasury(address _newTreasury)
        external
        AddressZero(_newTreasury)
        onlyOwner
    {
        treasury = _newTreasury;
    }

    /**
       @notice Update new address of Verifier
       @dev    Caller must be Owner
       @param _newVerifier Address of new Verifier
     */
    function updateVerifier(address _newVerifier)
        external
        AddressZero(_newVerifier)
        onlyOwner
    {
        verifier = _newVerifier;
    }

    /**
       @notice Change new address of Minter
       @dev    Caller must be Owner
       @param _newMinter Address of new Minter
     */
    function updateMinter(address _newMinter)
        external
        AddressZero(_newMinter)
        onlyOwner
    {
        minter = _newMinter;
    }

    /**
        @notice Update new random service
        @dev    Caller must be Owner
        @param  _newService    Address of new random service
     */
    function updateRandomService(address _newService)
        external
        AddressZero(_newService)
        onlyOwner
    {
        randomService = IRegistry(_newService);
    }

    /**
       @notice Update new address of NFT
       @dev    Caller must be Owner
       @param _microNFT Address of new NFT
     */
    function updateMicroNFT(address _microNFT)
        external
        AddressZero(_microNFT)
        onlyOwner
    {
        microphoneNFT = _microNFT;
    }

    /**
       @notice Update new address of loot box
       @dev    Caller must be Owner
       @param _lootBox Address of new loot box
     */
    function updateLootBox(address _lootBox)
        external
        AddressZero(_lootBox)
        onlyOwner
    {
        lootBox = _lootBox;
    }

    /**
       @notice Update new address of breeding contract
       @dev    Caller must be Owner
       @param _breeding Address of breeding contract
     */
    function updateBreeding(address _breeding)
        external
        AddressZero(_breeding)
        onlyOwner
    {
        breeding = _breeding;
    }

    /**
       @notice Update new address of ruby contract
       @dev    Caller must be Owner
       @param _ruby Address of ruby contract
     */
    function updateRuby(address _ruby) external onlyOwner {
        ruby = _ruby;
    }

    /**
       @notice Update new address of BUSD contract
       @dev    Caller must be Owner
       @param _busd Address of BUSD contract
     */
    function updateBUSD(address _busd) external AddressZero(_busd) onlyOwner {
        busd = _busd;
    }

    /**
        @notice Generate random number from Verichains random service
        @dev    Caller must be Lootbox/Breeding contract
     */
    function getRandom() external returns (uint256) {
        address msgSender = _msgSender();
        require(
            msgSender == lootBox || msgSender == breeding,
            "Unauthorized: Lootbox or Breeding contract only"
        );
        uint256 key = 0xc9821440a2c2cc97acac89148ac13927dead00238693487a9c84dfe89e28a284;
        return randomService.randomService(key).random();
    }
}