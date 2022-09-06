// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/// @author: SWMS.de

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@manifoldxyz/creator-core-solidity/contracts/core/IERC721CreatorCore.sol";
import "@manifoldxyz/creator-core-solidity/contracts/extensions/ICreatorExtensionTokenURI.sol";
import "./structs/PixelSkullStructs.sol";

contract PixelSkull is AdminControl {
    address private _creator;
    ContractData private contractData;
    bool internal locked;

    mapping(string => NFTDataAttributes) private tokensData;
    mapping(address => bool) private whitelistedAddresses;
    mapping(address => bool) private premintAddresses;

    constructor(
        address creator,
        string[] memory hashes,
        address payable[] memory artists,
        address payable payoutAddress,
        address[] memory whitelist
    ) {
        _creator = creator;
        contractData.isActive = true;
        contractData.payoutAddress = payoutAddress;
        contractData.APIEndpoint = "ar://";
        contractData.isPresaleActive = true;
        contractData.price = 1000000000000000;

        setNftData(hashes, artists);
        addUsersToWhiteList(whitelist);
    }

    modifier collectableIsActive() {
        require(contractData.isActive);
        _;
    }
    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    event Mint(address indexed _to, string _hash, uint256 _tokenId);
    event Withdraw(address indexed _to, uint256 _value);

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function getTokenByHash(string memory hashString)
        public
        view
        collectableIsActive
        returns (uint256 tokenId)
    {
        bytes memory tempEmptyStringTest = bytes(hashString);
        require(tempEmptyStringTest.length > 5);
        return (tokensData[hashString].tokens);
    }

    function mint(address account, string memory imageHash)
        public
        payable
        collectableIsActive
        noReentrant
        returns (uint256 tokenId)
    {
        bytes memory testIfEmpty = bytes(imageHash);
        require(testIfEmpty.length > 10, "invalid hash");

        if (contractData.isPresaleActive) {
            require(whitelistedAddresses[account], "not on whitelist");
            require(!premintAddresses[account], "Address already premintet");
        }
        require(account != address(0), "mint to the zero address");
        require(msg.value == contractData.price, "Wrong price");
        require(tokensData[imageHash].artist != address(0), "invalid Artist");

        require(tokensData[imageHash].tokens == 0, "Edition sold out");
        if (contractData.isPresaleActive) {
            premintAddresses[account] = true;
        }
        
        uint256 newItemId = IERC721CreatorCore(_creator).mintExtension(account);
        tokensData[imageHash].tokens = newItemId;
        IERC721CreatorCore(_creator).setTokenURIExtension(
            newItemId,
            string(abi.encodePacked(contractData.APIEndpoint, imageHash))
        );
        emit Mint(account, imageHash, newItemId);
        withdraw(imageHash);
        return newItemId;
    }

    function addUsersToWhiteList(address[] memory _addressToWhitelist) private {
        for (uint256 i = 0; i < _addressToWhitelist.length; i += 1) {
            whitelistedAddresses[_addressToWhitelist[i]] = true;
        }
    }

    function addUserToWhiteList(address _addressToWhitelist)
        public
        adminRequired
    {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function removeUserFromWhiteList(address _addressToWhitelist)
        public
        adminRequired
    {
        whitelistedAddresses[_addressToWhitelist] = false;
    }

    function setApiEndpoint(string memory _apiEndpoint) public adminRequired {
        contractData.APIEndpoint = _apiEndpoint;
    }

    function setPayoutAddress(address payable _address) public adminRequired {
        contractData.payoutAddress = _address;
    }

    function setNftData(
        string[] memory _tokensData,
        address payable[] memory _artists
    ) public adminRequired {
        for (uint256 i = 0; i < _tokensData.length; i += 1) {
            tokensData[_tokensData[i]] = NFTDataAttributes({
                artist: _artists[i],
                tokens: 0
            });
        }
    }

    function updateNftData(
        string memory hashString,
        NFTDataAttributes memory newTokenData
    ) public adminRequired {
        tokensData[hashString] = newTokenData;
    }

    function setIsActive(bool _isActive) public adminRequired {
        contractData.isActive = _isActive;
    }

    function setIsPresaleActive(bool _isActive, uint256 _price)
        public
        adminRequired
    {
        contractData.isPresaleActive = _isActive;
        contractData.price = _price;
    }

    function setlocked(bool status) public adminRequired {
        locked = status;
    }

    function withdraw(string memory imageHash) private {
        uint256 valueTransferArtist = msg.value * 70 / 100;
        uint256 valueTransferOwner = msg.value - valueTransferArtist;
        (bool success, ) = tokensData[imageHash].artist.call{
            value: valueTransferArtist
        }("");
        require(success, "Artist payout failed.");
        emit Withdraw(tokensData[imageHash].artist, valueTransferArtist);
        (bool success2, ) = contractData.payoutAddress.call{
            value: valueTransferOwner
        }("");
        require(success2, "payoutAddress payout failed.");
        emit Withdraw(contractData.payoutAddress, valueTransferOwner);
    }

    function payout() public adminRequired noReentrant collectableIsActive{
        uint256 sendAmount = address(this).balance;
        address creator = contractData.payoutAddress;

        (bool success, ) = creator.call{value: (sendAmount)}("");
        require(success, "Transaction Unsuccessful");
        emit Withdraw(creator, sendAmount);
    }
}