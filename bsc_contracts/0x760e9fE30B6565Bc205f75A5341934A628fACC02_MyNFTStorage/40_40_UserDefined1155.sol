// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";

import "./AdminContract.sol";

/**
- Contract uses a single URI which is the monion IPFS URI for hosting metadata
- Contract relies on the metadata to store relevant info about the token such as name, description etc.
- Contract issues tokenId to each token minted
- Contract use is cheaper than if the user deployed a fresh instance of the ERC1155

*/

contract UserDefined1155 is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC2981,
    ERC1155ReceiverUpgradeable,
    ERC1155SupplyUpgradeable,
    ERC1155HolderUpgradeable,
    UUPSUpgradeable,
    RoyaltiesV2Impl
{
    address operator;
    AdminConsole admin;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint96 defaultRoyalty;
    string private myUri;

    event Minted(
        uint indexed tokenId,
        address indexed owner,
        address indexed nftAddress,
        uint quantity
    );

    function initialize(address _operator, address _admin) public initializer {
        myUri = "https://storage.googleapis.com/contnft-staging/{id}.json";
        defaultRoyalty = 1000;
        operator = _operator;
        admin = AdminConsole(_admin);

        __ERC1155_init(
            myUri
        );
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function getURI() public view returns (string memory) {
        return myUri;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setContructor(address _operator, address _admin) public onlyOwner {
        operator = _operator;
        admin = AdminConsole(_admin);
    }

    function getConstructor() public view returns (address, address) {
        return (operator, admin.getOwner());
    }

    function mint(address account, uint quantity, uint96 royalty) public {
        _tokenIdTracker.increment();
        require(royalty >= 0);
        require(royalty <= 5000);
        uint tokenId = _tokenIdTracker.current();
        _mint(account, tokenId, quantity, "");
        setApprovalForAll(operator, true);
        if (royalty > 0) setRoyalties(tokenId, payable(account), royalty);
        //Should I generate a hex code using the tokenId, so that the hex code is used to create a link?
        emit Minted(tokenId, account, address(this), quantity);
    }

    function getTokenCount() public view returns (uint) {
        return _tokenIdTracker.current();
    }

    function _beforeTokenTransfer(
        address theOperator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(theOperator, from, to, ids, amounts, data);
    }

    function setRoyalties(
        uint _tokenId,
        address payable _royaltiesReceipientAddress,
        uint96 _percentageBasisPoints
    ) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function getRoyalties(
        uint _tokenId
    )
        public
        view
        returns (address[] memory receipent, uint96[] memory percent)
    {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        uint256 length = _royalties.length;
        address[] memory r1 = new address[](length);
        uint96[] memory r2 = new uint96[](length);

        for (uint i = 0; i < _royalties.length; i++) {
            r1[i] = _royalties[i].account;
            r2[i] = _royalties[i].value;
        }
        return (r1, r2);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981, ERC1155ReceiverUpgradeable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}