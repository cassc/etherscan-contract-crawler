// SPDX-License-Identifier: Apache-2.0
// Copyright © 2020 UBISOFT

pragma solidity ^0.5.0;

import "./ERC721Leveled.sol";
import "./ENS.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Pausable.sol";

interface MoonOracle {
    /**
    * @notice Checks wether a timestamp occurs during a full moon
    * @param timestamp The timestamp in Unix epoch in seconds
    * @return True if the timestamp approximately matches a full moon day
    */
    function isFull(uint256 timestamp) external pure returns (bool);
}

interface PopoToken {
    /**
    * @notice Reward an address with a POPO token
    * @dev If the receiver already owns a POPO of this level and serie, do not mint any token
    * @param receiver The address that will receive the POPO token
    * @param serie The Rabbid token id
    * @param level The level that will be set on the token
    */
    function reward(address receiver, uint256 serie, uint256 level) external;
}

/**
* @notice The Rabbids contract is an ERC721 compatible token with special Rabbid features
*/
contract Rabbids is ERC721, ERC721Enumerable, ERC721Leveled, ERC721Pausable {
    // Ethereum Name Service contract
    ENS private _ens;

    // Terms and conditions of use
    string private _aboutURI;

    // UNICEF address
    address payable public unicef;
    // UNICEF ENS in bytes32s
    bytes32 public unicefNode;
    // Decide to use UNICEF ens or address
    bool public useENS;

    // Popo contract address
    PopoToken private _popo;

    // Moon oracle address
    MoonOracle private _moon;

    // Rabbid steal counter
    mapping(uint256 => uint256) public stealCount;

    // Rabbid raised total value
    mapping(uint256 => uint256) public totalRaised;

    // Minimum donation to steal the token : 0.05 ETH
    uint256 private _baseDonation = 50000000000000000;
    // Donation multiplied by rabbid's level : 0.01 ETH * rabbidLevel[tokenId]
    uint256 private _incrementalDonation = 10000000000000000;
    // Specific donation for stealing the rabbid level 0 : 0.2 ETH
    uint256 private _specialDonation = 200000000000000000;

    // Rabbid has been stolen!
    event Bwaaah(uint256 indexed id, address indexed receiver, uint256 level);

    /**
    * @notice Initialize the token
    * @param _name The token name
    * @param _symbol The token symbol
    * @param _maximumLevel The maximum level that can be set on the token
    */
    constructor(string memory _name, string memory _symbol, uint256 _maximumLevel)
        public
        ERC721Leveled(_name, _symbol, _maximumLevel)
    {}

    /**
    * @notice Steal this token in exchange of a small donation
    * @param tokenId the token to steal
    * */
    function steal(uint256 tokenId) public payable {
        (uint256 newRabbidLevel, uint256 popoRewardLevel) = _stealLevel(tokenId);
        
        // Check donation
        uint256 requiredDonation = _getRequiredDonation(popoRewardLevel);
        require(msg.value >= requiredDonation, "BWAAAAH! I want more ETH!");
        require(msg.value <= requiredDonation, "BWAAAAH! Too much ETH!");

        stealCount[tokenId] += 1;
        totalRaised[tokenId] += msg.value;

        // Level-up and reward!
        _setLevel(tokenId, newRabbidLevel);
        _popo.reward(msg.sender, tokenId, popoRewardLevel);

        // The Rabbid now goes to the thief
        _safeTransferFrom(ownerOf(tokenId), msg.sender, tokenId, "");

        // Make some useless noise
        emit Bwaaah(tokenId, msg.sender, popoRewardLevel);

        address payable _unicef = resolveUnicefAddress();
        // Do at least one useful thing
        _unicef.transfer(msg.value);
    }

    /**
     * @notice Obtains the level for the token when steal is performed.
     * @param tokenId uint256 Token to be stolen
     */
    function _stealLevel(uint256 tokenId) internal view returns (uint256 tokenRewardLevel, uint256 popoRewardLevel) {
        uint256 currentLevel = this.tokenLevel(tokenId);

        popoRewardLevel = currentLevel;
        tokenRewardLevel = currentLevel + 1;

        if (_moon.isFull(now)) {
            // Full moon turns the Rabbids to a zombie. Thief get a Zombie POPO
            tokenRewardLevel = 0;
            popoRewardLevel = 0;
        }
        else if (currentLevel == 0) {
            // Do not reward zombie POPO outside of full moons, fall back to lvl 1
            popoRewardLevel = 1;
        } else if (tokenRewardLevel > _maxLevel) {
            // Roll back token level to 1
            tokenRewardLevel = 1;
        }
    }

    /**
    * @notice Minting function. Rabbids are a limited edition.
    * @param receiver Address that receives the minted token
    * @return Id of minted token
    */
    function reward(address receiver) public onlyMinter returns (uint256) {
        uint256 _lastTokenId = totalSupply() + 1;
        require(_lastTokenId < 6, "No more token can be created");

        _mint(receiver, _lastTokenId);
        _setLevel(_lastTokenId, 1);
        _setSerie(_lastTokenId, _lastTokenId);
        _popo.reward(receiver, _lastTokenId, 1);

        return _lastTokenId;
    }

    /**
     * @dev function to get the required donation to steal a token
     * @param _tokenLevel uint256 Level of the token to be stolen
     * @return uint256 donation amount
     *
     */
    function _getRequiredDonation(uint256 _tokenLevel)
        internal
        view
        returns (uint256)
    {
        if (_tokenLevel == 0){
            return _specialDonation;
        } else {
            return _baseDonation + (_incrementalDonation * _tokenLevel);
        }
    }
    
    /**
     * @dev function to get the required donation to steal a token
     * @return uint256 donation amount
     *
     */
    function getRequiredDonation(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        (,uint256 popoLevel) = _stealLevel(tokenId);
        return _getRequiredDonation(popoLevel);
    }

    /**
    * @notice Sets the donation address for stolen rabbids. At launch the owner of uniceffrance.eth is used
    */
    function setUnicefAddress(address payable to) public onlyOwner {
        unicef = to;
    }

    /**
     * @notice onlyOwner function to set the terms and conditions link
     * @param uri string IPFS URI where the t&c can be found
     *
     */
    function setAboutURI(string memory uri) public onlyOwner {
        _aboutURI = uri;
    }

    /**
    * @notice Updates the Moon oracle contract address
    */
    function setMoonOracle(address oracleAddress) public onlyOwner {
        _moon = MoonOracle(oracleAddress);
    }

    /**
    * @notice Updates the POPO token contract address
    */
    function setPopoContract(address popoAddress) public onlyOwner {
        _popo = PopoToken(popoAddress);
    }

    /**
    * @notice Updates the required donation to steal a Rabbid
    * @param baseDonation The base donation
    * @param incrementalDonation The additional donation per token level
    * @param specialDonation Specific donation for stealing the rabbid level 0
    */
    function setDonationBase(uint256 baseDonation, uint256 incrementalDonation, uint256 specialDonation)
        public
        onlyOwner
    {
        _baseDonation = baseDonation;
        _incrementalDonation = incrementalDonation;
        _specialDonation = specialDonation;
    }

    /**
    * @notice Updates the value of unicefNode
    * @param node hashed ENS record, see example below
    * namehash("bob.eth") == 0xbe11069ec59144113f438b6ef59dd30497769fc2dce8e2b52e3ae71ac18e47c9
    */
    function setUnicefNode(bytes32 node) public onlyOwner {
        unicefNode = node;
    }

    /**
    * @notice Returns the payable address for UNICEF Crypto Fund
    * @dev from ENS record if useENS == true 
    * from UNICEF's alternative address if useENS == false
    * revert if address is 0x0
    */
    function resolveUnicefAddress() public view returns (address payable) {
        address payable _unicef;
        if (useENS == false) {
            _unicef = unicef;
        } else {
            address _resolved = _resolve(unicefNode);
            _unicef = address(uint160(_resolved));
        }
        if (_unicef == address(0)) {
            revert("REVERT: UNICEF address not set");
        }
        return _unicef;
    }

    /**
    * @notice Returns the address linked to a node (hashed ENS record)
    * @param node bytes32 Value of the hashed ENS name
    * @return The address linked to a node
    */
    function _resolve(bytes32 node) internal view returns (address) {
        Resolver resolver = _ens.resolver(node);
        return resolver.addr(node);
    }

    /**
    * @notice Sets the ENS contract to a new address
    * @param addr address of the ens registrar
    */
    function setENSRegistrar(address addr) public onlyOwner {
        _ens = ENS(addr);
    }

    /**
    * @notice Updates the useENS to use ENS or not
    * @param value boolean
    */
    function setUseENS(bool value) public onlyOwner {
        useENS = value;
    }
    
    /*
    *   GETTERS
    */
    
    /**
     * @notice returns the terms and conditions link for this contract
     * @return the uri where the t&c can be found
     *
     */
    function about() public view returns (string memory) {
        return _aboutURI;
    }
    
    /**
     * @notice Retrieve the address for the ENS contract
     */
    function ENSAddress() external view returns (address) {
        return address(_ens);
    }
    
    /**
     * @notice Retrieve the address for the POPO token contract
     */
    function POPOTokenAddress() external view returns (address) {
        return address(_popo);
    }
    
    /**
     * @notice Retrieve the address for the MoonOracle contract
     */
    function MoonOracleAddress() external view returns (address) {
        return address(_moon);
    }
    
    /**
     * @notice Retrieve the values for calculating the donation
     */
    function DonationBase() external view returns (uint256 baseDonation, uint256 incrementalDonation, uint256 specialDonation) {
        return (_baseDonation, _incrementalDonation, _specialDonation);
    }
}