// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721AQueryable} from "ERC721A/extensions/ERC721AQueryable.sol";
import "ERC721A/ERC721A.sol";
import {IERC2981, ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "./IERC4906.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";

enum TicketID {
    AllowList,
    FamilySale
}

error PreMaxExceed(uint256 _presaleMax);
error MaxSupplyOver();
error NotEnoughFunds(uint256 balance);
error NotMintable();
error InvalidMerkleProof();
error AlreadyClaimedMax();
error MintAmountOver();

contract MEMEME is
    ERC721A,
    IERC4906,
    ERC721AQueryable,
    OperatorFilterer,
    AccessControl,
    ERC2981,
    Ownable
{
    uint256 private constant PUBLIC_MAX_PER_TX = 10;
    uint256 private constant PRE_MAX_CAP = 100;
    uint256 public constant MAX_SUPPLY = 2222;
    string private constant BASE_EXTENSION = ".json";
    address private constant FUND_ADDRESS =
        0xe40A3e5ca69074fa5b355EaBbd98abf1CBF9f76F;
    address private constant ADMIN_ADDRESS =
        0xD10f111E936E7d0C153Bd659E4AC40bB5C7DE1D9;
    address private constant DEV_ADDRESS =
        0x60384911A63AcC5C0A9eB3790F8FFf32b4A0135D;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public publicSale = false;
    bool public callerIsUserFlg = false;
    bool public mintable = false;
    bool public operatorFilteringEnabled = true;
    bool public renounceOwnerMintFlag = false;

    uint256 public publicCost = 0.0333 ether;
    string private baseURI =
        "ar://oxHgu_PVI3G9JJgwcaZBmvEBxhPpdB-Mk_LOxQBsV9Q/";

    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(uint256 => string) private metadataURI;

    constructor(bool _callerIsUserFlg) ERC721A("MEMEME", "MEMEME") {
        _registerForOperatorFiltering();
        _setDefaultRoyalty(ADMIN_ADDRESS, 750);
        callerIsUserFlg = _callerIsUserFlg;
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        _grantRole(MINTER_ROLE, owner());
        if (_callerIsUserFlg) {
            _mintERC2309(ADMIN_ADDRESS, 99);
        }

        presaleCost[TicketID.AllowList] = 0.018 ether;
        presaleCost[TicketID.FamilySale] = 0.018 ether;
    }

    modifier whenMintable() {
        if (mintable == false) revert NotMintable();
        _;
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        if (callerIsUserFlg == true) {
            require(tx.origin == msg.sender, "The caller is another contract");
        }
        _;
    }

    // internal
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (bytes(metadataURI[tokenId]).length == 0) {
            return
                string(
                    abi.encodePacked(ERC721A.tokenURI(tokenId), BASE_EXTENSION)
                );
        } else {
            return metadataURI[tokenId];
        }
    }

    function setTokenMetadataURI(
        uint256 tokenId,
        string memory metadata
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        metadataURI[tokenId] = metadata;
        emit MetadataUpdate(tokenId);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Set the merkle root for the allow list mint
     */
    function setMerkleRoot(
        bytes32 _merkleRoot,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot[ticket] = _merkleRoot;
    }

    function setCallerIsUserFlg(
        bool flg
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        callerIsUserFlg = flg;
    }

    function publicMint(
        address _to,
        uint256 _mintAmount
    ) external payable callerIsUser whenMintable {
        if (_totalMinted() + _mintAmount > MAX_SUPPLY) revert MaxSupplyOver();
        if (msg.value < publicCost * _mintAmount)
            revert NotEnoughFunds(msg.value);
        if (!publicSale) revert NotMintable();
        if (_mintAmount > PUBLIC_MAX_PER_TX) revert MintAmountOver();

        _mint(_to, _mintAmount);
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _presaleMax,
        bytes32[] calldata _merkleProof,
        TicketID ticket
    ) external payable whenMintable {
        if (_presaleMax > PRE_MAX_CAP) revert PreMaxExceed(_presaleMax);
        if (_totalMinted() + _mintAmount > MAX_SUPPLY) revert MaxSupplyOver();
        if (msg.value == 0 || msg.value < presaleCost[ticket] * _mintAmount)
            revert NotEnoughFunds(msg.value);
        if (!presalePhase[ticket]) revert NotMintable();
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _presaleMax));
        uint64 claimed = getWhiteListClaimed(ticket, msg.sender) +
            uint64(_mintAmount);
        if (!MerkleProof.verifyCalldata(_merkleProof, merkleRoot[ticket], leaf))
            revert InvalidMerkleProof();
        if (claimed > _presaleMax) revert AlreadyClaimedMax();

        _mint(msg.sender, _mintAmount);
        setWhiteListClaimed(ticket, msg.sender, claimed);
    }

    function setWhiteListClaimed(
        TicketID ticket,
        address account,
        uint64 claimed
    ) internal {
        uint64 packedData = (claimed << 32) | uint64(ticket);
        _setAux(account, packedData);
    }

    function getWhiteListClaimed(
        TicketID ticket,
        address account
    ) public view returns (uint64) {
        uint64 packedData = _getAux(account);
        uint64 savedTicket = packedData & uint64((1 << 32) - 1);
        uint64 claimed = packedData >> 32;
        if (savedTicket != uint64(ticket)) {
            return 0;
        }
        return claimed;
    }

    function ownerMint(
        address _address,
        uint256 count
    ) external onlyRole(MINTER_ROLE) {
        require(!renounceOwnerMintFlag, "owner mint renounced");
        _safeMint(_address, count);
    }

    function setPresalePhase(
        bool _state,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presalePhase[ticket] = _state;
    }

    function setPresaleCost(
        uint256 _cost,
        TicketID ticket
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleCost[ticket] = _cost;
    }

    function setPublicCost(
        uint256 _publicCost
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicCost = _publicCost;
    }

    function setPublicPhase(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSale = _state;
    }

    function setMintable(bool _state) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintable = _state;
    }

    function setBaseURI(
        string memory _newBaseURI
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(_startTokenId(), totalSupply());
    }

    function withdraw() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        uint256 devShare = balance / 10;
        uint256 fundShare = balance - devShare;

        payable(DEV_ADDRESS).transfer(devShare);
        payable(FUND_ADDRESS).transfer(fundShare);
    }

    function renounceOwnerMint() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        renounceOwnerMintFlag = true;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981, AccessControl)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}