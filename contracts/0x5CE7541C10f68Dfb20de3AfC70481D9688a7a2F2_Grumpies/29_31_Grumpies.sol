// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721Upgradeable, IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";
import "./SignedAllowance.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC2981Upgradeable, ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC721ConsecutiveUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721ConsecutiveUpgradeable.sol";

//
//
//               _  .-')                 _   .-')       _ (`-.               ('-.     .-')
//              ( \( -O )               ( '.( OO )_    ( (OO  )            _(  OO)   ( OO ).
//   ,----.      ,------.   ,--. ,--.    ,--.   ,--.) _.`     \   ,-.-')  (,------. (_)---\_)
//  '  .-./-')   |   /`. '  |  | |  |    |   `.'   | (__...--''   |  |OO)  |  .---' /    _ |
//  |  |_( O- )  |  /  | |  |  | | .-')  |         |  |  /  | |   |  |  \  |  |     \  :` `.
//  |  | .--, \  |  |_.' |  |  |_|( OO ) |  |'.'|  |  |  |_.' |   |  |(_/ (|  '--.   '..`''.)
// (|  | '. (_/  |  .  '.'  |  | | `-' / |  |   |  |  |  .___.'  ,|  |_.'  |  .--'  .-._)   \
//  |  '--'  |   |  |\  \  ('  '-'(_.-'  |  |   |  |  |  |      (_|  |     |  `---. \       /
//   `------'    `--' '--'   `-----'     `--'   `--'  `--'        `--'     `------'  `-----'
//
//
//
/// @title Grumpies
/// @author aceplxx (https://twitter.com/aceplxx)

enum SaleState {
    Paused,
    Presale,
    Public
}

contract Grumpies is
    ERC721ConsecutiveUpgradeable,
    UUPSUpgradeable,
    OperatorFilterer,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    SignedAllowance
{
    SaleState public saleState;
    string public baseURI;
    address public constant VAULT = 0xC6A6169AC9169346cfDFece14f4551E7938b9e75;
    uint256 public constant MAX_SUPPLY = 4000;
    uint256 public constant TEAM_RESERVES = 100;
    uint256 private totalSupply_;
    uint256 public price;
    uint256 public supplyBurnt;

    bool public operatorFilteringEnabled;

    bytes32 public presaleRoot;

    mapping(address => uint256) public minted;
    mapping(address => uint256) public commit;
    uint256 public totalCommit;

    error SaleNotActive();

    function initialize(address allowancesSigner_) public initializer {
        __ERC721_init("Grumpies", "GRUMPIES");
        __Ownable_init();
        __ERC2981_init();
        __ERC721Consecutive_init();

        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        //7% royalty.
        _setDefaultRoyalty(VAULT, 700);

        _setAllowancesSigner(allowancesSigner_);
        _mintConsecutive(VAULT, 100);
        baseURI = "https://curious-figolla-f81e33.netlify.app/api/metadata/";
        price = 0.028 ether;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @notice sets allowance signer, this can be used to revoke all unused allowances already out there
    /// @param newSigner the new signer
    function setAllowancesSigner(address newSigner) external onlyOwner {
        _setAllowancesSigner(newSigner);
    }

    function setPresaleRoot(bytes32 _root) external onlyOwner {
        presaleRoot = _root;
    }

    function setSaleState(SaleState state) external onlyOwner {
        saleState = state;
    }

    function setMintConfig(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function burnSupply(uint256 amount) external onlyOwner {
        supplyBurnt += amount;
    }

    function withdraw() external onlyOwner {
        bool success;
        (success, ) = payable(VAULT).call{value: address(this).balance}("");
        require(success, "failed");
    }

    function _isWhitelisted(bytes32[] calldata _merkleProof, address _address)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        bool whitelisted;
        whitelisted = MerkleProofUpgradeable.verify(
            _merkleProof,
            presaleRoot,
            leaf
        );
        return whitelisted;
    }

    function _totalSupply() internal view returns (uint256) {
        return totalSupply_ + TEAM_RESERVES;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI()
        internal
        view
        virtual
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return baseURI;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    function commitToMint(bytes32[] calldata proof) external payable {
        require(totalCommit + TEAM_RESERVES <= MAX_SUPPLY, "supply not enough");
        require(msg.value >= price, "G: Price incorrect");

        bool eligible = true;

        if (saleState == SaleState.Presale) {
            require(commit[_msgSender()] == 0, "already commit");
            require(minted[_msgSender()] == 0, "G: Max minted WL");
            eligible = _isWhitelisted(proof, _msgSender());
        } else if (saleState != SaleState.Public) {
            revert SaleNotActive();
        }

        if (eligible) {
            commit[_msgSender()]++;
            totalCommit++;
        }
    }

    function presaleMint(bytes calldata signature, uint256 tokenId) external {
        if (saleState != SaleState.Presale) revert SaleNotActive();
        require(minted[_msgSender()] == 0, "G: Max minted WL");
        require(commit[_msgSender()] > 0, "no commit left");
        _useAllowance(_msgSender(), tokenId, signature);
        minted[_msgSender()]++;
        totalSupply_++;
        commit[_msgSender()]--;
        _mint(_msgSender(), tokenId);
    }

    function publicMint(bytes calldata signature, uint256 tokenId) external {
        if (saleState != SaleState.Public) revert SaleNotActive();
        require(commit[_msgSender()] > 0, "no commit left");
        _useAllowance(_msgSender(), tokenId, signature);
        totalSupply_++;
        _mint(_msgSender(), tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721Upgradeable) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981Upgradeable, ERC721Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator)
        internal
        pure
        override
        returns (bool)
    {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}