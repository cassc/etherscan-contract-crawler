// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./@rarible/royalties/contracts/LibPart.sol";

contract Flashtronauts is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
    struct RoyaltyInformation {
        address payable receiver;
        uint96 percentageBasisPoints;
    }

    RoyaltyInformation royaltyInformation =
    RoyaltyInformation(payable(0x8603FfE7B00CCd759f28aBfE448454A24cFba581), 880);

    address public superAdmin;

    string contractURI = "ipfs://QmS5MRcgJUKENJftueDaM5EA3KrimBmf5wJDUoDsiDkgoT/collection.json";
    string baseURI = "ipfs://QmRuwqugVBcVTLED6aD12buPZujnwSSTB2D1bHBnV9ruCs/";

    event RoyaltyDetailsUpdated(address _newRoyaltyReceiver, uint96 _newFeeBp);
    event MintFeeInfoUpdated(address _mintFeeRecipient, address _mintFeeTokenAddress, uint96 _mintFee);

    constructor(address _mintTo) public ERC721("Flashtronauts", "Flashtronauts") {
        superAdmin = msg.sender;

        // Mint all 121 Flashtronauts
        for(uint8 i = 1; i <= 121; i++) {
            tokenIds.increment();
            _mint(_mintTo, tokenIds.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function burn(uint256 _tokenId) public returns (bool) {
        require(msg.sender == ownerOf(_tokenId), "NOT OWNER");

        _burn(_tokenId);
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return tokenIds.current();
    }

    function bulkMintPrivileged(address[] memory _recipientAddresses)
    public
    onlySuperAdmin
    {
        for (uint256 i = 0; i < _recipientAddresses.length; i++) {
            tokenIds.increment();
            _mint(_recipientAddresses[i], tokenIds.current());
        }
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721) returns (bool) {
        if (_interfaceId == _INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (_interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(_interfaceId);
    }

    function setRoyaltyDetails(address payable _defaultRoyaltyReceiver, uint96 _defaultPercentageBasisPoints)
    onlySuperAdmin
    external
    returns (bool)
    {
        royaltyInformation.receiver = _defaultRoyaltyReceiver;
        royaltyInformation.percentageBasisPoints = _defaultPercentageBasisPoints;
        emit RoyaltyDetailsUpdated(_defaultRoyaltyReceiver, _defaultPercentageBasisPoints);
        return true;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyInformation.receiver, (_salePrice * royaltyInformation.percentageBasisPoints) / 10000);
    }

    function getRaribleV2Royalties(uint256 _id) external view returns (LibPart.Part[] memory) {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = royaltyInformation.percentageBasisPoints;
        _royalties[0].account = royaltyInformation.receiver;
        return _royalties;
    }

    function setBaseURI(string calldata _newBaseURI) onlySuperAdmin external {
        baseURI = _newBaseURI;
    }

    function transferSuperAdmin(address _newSuperAdmin) onlySuperAdmin external {
        superAdmin = _newSuperAdmin;
    }

    function setOwner(address _newOwner) onlySuperAdmin external {
        // This function serves to allow the super admin to update the owner
        _transferOwnership(_newOwner);
    }

    modifier onlySuperAdmin() {
        require(msg.sender == superAdmin, "NOT SUPER ADMIN");
        _;
    }
}