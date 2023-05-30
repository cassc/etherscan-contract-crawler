// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {ERC721AQueryable} from "ERC721A/extensions/ERC721AQueryable.sol";
import "ERC721A/ERC721A.sol";
import {IERC2981, ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "./IERC4906.sol";
import {OperatorFilterer} from "closedsea/OperatorFilterer.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "contracts/extension/ContractMetadata.sol";

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

contract iPadmateDoodle is
    ERC721A,
    IERC4906,
    ERC721AQueryable,
    OperatorFilterer,
    AccessControl,
    ERC2981,
    Ownable,
    ContractMetadata,
    Pausable
{
    uint256 private constant PUBLIC_MAX_PER_TX = 10;
    uint256 private constant PRE_MAX_CAP = 20;
    string private constant BASE_EXTENSION = ".json";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public immutable MAX_SUPPLY;
    address private immutable FUND_ADDRESS;

    bool public publicSale = false;
    bool public callerIsUserFlg = false;
    bool public mintable = false;
    bool public operatorFilteringEnabled = true;
    bool public renounceOwnerMintFlag = false;

    uint256 public publicCost = 0.15 ether;
    string private baseURI =
        "ar://5gPkkVh99O5nTNapYZ3-PS_fvIgnKhMVFLBwedgTnnE/";

    mapping(TicketID => bool) public presalePhase;
    mapping(TicketID => uint256) public presaleCost;
    mapping(TicketID => bytes32) public merkleRoot;
    mapping(uint256 => string) private metadataURI;

    address public deployer;

    constructor(
        string memory _name,
        string memory _symbol,
        bool mintERC2309
    ) ERC721A(_name, _symbol) {
        _registerForOperatorFiltering();
        _grantRole(DEFAULT_ADMIN_ROLE, owner());
        _grantRole(MINTER_ROLE, owner());
        if (mintERC2309) {
            _mintERC2309(0x5693eF3d399D06149C361FD6DFa85Ab85f4579AB, 110);
        }

        MAX_SUPPLY = 1810;
        FUND_ADDRESS = 0xB151b9a5d64fd9BA89CDfA34cA045763f786B908;
        presaleCost[TicketID.AllowList] = 0.15 ether;
        presaleCost[TicketID.FamilySale] = 0.15 ether;
        deployer = msg.sender;
    }

    /**
     *  This function returns who is authorized to set the metadata for your metadata.
     */
    function _canSetContractURI()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == deployer;
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
    ) external payable whenNotPaused callerIsUser whenMintable {
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
    ) external payable whenMintable whenNotPaused {
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

    function checkClaimEligibility(
        uint256 quantity
    ) external view returns (string memory) {
        if (paused()) {
            return "Sale period is not live.";
        } else if (mintable == false) {
            return "Sale period is not live.";
        } else if (publicSale == false) {
            return "Sale period is not live.";
        } else if (quantity <= 0) {
            return "Quantity can not be 0";
        } else if (quantity > PUBLIC_MAX_PER_TX) {
            return "Exceeded max mint amount per transaction.";
        } else if (totalSupply() + quantity > MAX_SUPPLY) {
            return "Not enough supply";
        }
        return "";
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

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function withdraw() external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        payable(FUND_ADDRESS).transfer(balance);
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