// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";


interface INftSubcontract {
    function uri(uint256 id) external view returns (string memory);
}

contract RainiCardsv2 is ERC1155, IERC2981, DefaultOperatorFilterer, Ownable2Step, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    string public baseUri;
    string public contractURIString;
    INftSubcontract public subContract;
    address private contractOwner;

    address private _royaltiesRecipient;
    uint256 private _royaltiesBasisPoints;

    constructor(
        string memory _uri,
        string memory _contractURIString,
        address _contractOwner
    ) ERC1155(_uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _contractOwner);
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        baseUri = _uri;
        contractOwner = _contractOwner;
        contractURIString = _contractURIString;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE, _msgSender()), "caller is not a burner");
        _;
    }

    function setcontractURI(string memory _contractURIString)
        external
        onlyAdmin
    {
        contractURIString = _contractURIString;
    }

    function setBaseURI(string memory _baseURIString) external onlyAdmin {
        baseUri = _baseURIString;
    }

    function getTotalBalance(address _address, uint256 _cardCount)
        external
        view
        returns (uint256[][] memory amounts)
    {
        uint256[][] memory _amounts = new uint256[][](
            _cardCount
        );
        uint256 count;
        for (uint256 i = 1; i <= _cardCount; i++) {
            uint256 balance = balanceOf(_address, i);
            if (balance != 0) {
                _amounts[count] = new uint256[](2);
                _amounts[count][0] = i;
                _amounts[count][1] = balance;
                count++;
            }
        }

        uint256[][] memory _amounts2 = new uint256[][](count);
        for (uint256 i = 0; i < count; i++) {
            _amounts2[i] = new uint256[](2);
            _amounts2[i][0] = _amounts[i][0];
            _amounts2[i][1] = _amounts[i][1];
        }

        return _amounts2;
    }

    function mint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyMinter {
        _mint(_to, _tokenId, _amount, "");
    }

    function mintBatch(address[] memory to, uint256[] memory ids, uint256[] memory amounts)
        external onlyMinter {
        if (to.length == 1) {
            _mintBatch(to[0], ids, amounts, "");
        } else {
            for (uint256 i = 0; i < to.length; i++) {
                _mint(to[i], ids[i], amounts[i], "");
            }
        }
    }

    function burn(
        address _owner,
        uint256 _tokenId,
        uint256 _amount
    ) external onlyBurner {
        _burn(_owner, _tokenId, _amount);
    }

    function updateSubContract(address _contractAddress)
        external
        onlyAdmin
    {
        subContract = INftSubcontract(_contractAddress);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {

        if (address(subContract) == address(0)) {
            return
                string(
                    abi.encodePacked(
                        baseUri,
                        "?cid=",
                        Strings.toString(id)
                    )
                );
        } else {
            return subContract.uri(id);
        }
    }

    function contractURI() public view returns (string memory) {
        return contractURIString;
    }


    /** EIP2981 royalties implementation. */

    function setRoyalties(address newRecipient, uint256 basisPoints) external onlyOwner {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        _royaltiesRecipient = newRecipient;
        _royaltiesBasisPoints = basisPoints;
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltiesRecipient, (_salePrice * _royaltiesBasisPoints) / 10000);
    }



    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}