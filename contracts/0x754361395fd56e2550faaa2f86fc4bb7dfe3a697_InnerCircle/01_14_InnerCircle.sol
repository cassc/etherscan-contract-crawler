// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC721A } from 'ERC721A/ERC721A.sol';
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { IERC2981, ERC2981 } from 'openzeppelin-contracts/token/common/ERC2981.sol';
import { OperatorFilterer } from "closedsea/OperatorFilterer.sol";
import { Ownable } from 'openzeppelin-contracts/access/Ownable.sol';
import { ReentrancyGuard } from 'openzeppelin-contracts/security/ReentrancyGuard.sol';
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ICentralBroCommittee } from './interfaces/ICentralBroCommittee.sol';

error InvalidMintPhase();
error MaxSupplyOfPhaseReached();
error MintingNotOpen();
error TeamMintAlreadyComplete();
error WalletAlreadyMinted();

contract InnerCircle is ERC721A, OperatorFilterer, Ownable, ERC2981, ReentrancyGuard, ICentralBroCommittee {

    using SafeTransferLib for ERC20;

    struct MintPhase {
        uint256 price;
        uint256 supply;
        address beneficiary;
        bool isOpen;
        uint256 numMinted;
    }

    mapping(uint256 => MintPhase) public mintPhases;
    bool public operatorFilteringEnabled;

    /// @notice The address of the CBDC ERC20 token contract.
    ERC20 public constant CBDCToken = ERC20(0xE6E6633cA1e0a80F8c63Aea9fC63cd2D3092A046);

    /// @notice Number of CBDC tokens required to be a part of the Inner Circle for phase 1.
    uint256 public immutable PHASE_1_PRICE = 3_500_000_000 * 10 ** CBDCToken.decimals();

    /// @notice Number of Inner Circle members allowed to mint for phase 1.
    uint256 public constant PHASE_1_SUPPLY = 15;

    /// @notice Number of CBDC tokens required to be a part of the Inner Circle for phase 2.
    uint256 public immutable PHASE_2_PRICE = 3_500_000_000 * 10 ** CBDCToken.decimals();

    /// @notice Number of Inner Circle tokens allowed to mint for phase 2.
    uint256 public constant PHASE_2_SUPPLY = 15;

    /// @notice Number of Inner Circle tokens to be minted by team.
    uint256 public constant TEAM_SUPPLY = 15;

    /// @notice Maximum number of mintable Inner Circle tokens.
    uint256 public constant MAX_SUPPLY = PHASE_1_SUPPLY + PHASE_2_SUPPLY + TEAM_SUPPLY;

    // tracks which wallets have minted
    mapping(address => bool) private _addressesMinted;

    // tracks at what block the CBDC nft is received.
    mapping(address => uint256) private _receivedBlock;

    // tracks if the team has minted
    bool private _hasTeamMinted;
    string private _baseUri;

    constructor() ERC721A("Central Bro's Inner Circle", "CBIC") {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;

        // sets royalty receiver to the contract creator, at 5% (default denominator is 10000).
        _setDefaultRoyalty(0x544d30967E2ECB5305736f5fDcC9C81e811D046A, 500);
        setBaseURI('ipfs://QmXTvEfY5ttK3353T9LKFgHkrSpRAhsfBngjpdR9FHjUkf/');

        mintPhases[1] = MintPhase({
            price: PHASE_1_PRICE,
            supply: PHASE_1_SUPPLY,
            beneficiary: 0x544d30967E2ECB5305736f5fDcC9C81e811D046A,
            isOpen: false,
            numMinted: 0
        });

        mintPhases[2] = MintPhase({
            price: PHASE_2_PRICE,
            supply: PHASE_2_SUPPLY,
            beneficiary: 0x544d30967E2ECB5305736f5fDcC9C81e811D046A,
            isOpen: false,
            numMinted: 0
        });
    }

    
    /// @notice Mint to become part of the Central Bro's Inner Circle.
    function mint() external nonReentrant {
        MintPhase memory phase1 = mintPhases[1];
        MintPhase memory phase2 = mintPhases[2];
        MintPhase storage currentPhase;

        if(!phase1.isOpen && !phase2.isOpen) {
            revert MintingNotOpen();
        }

        if(_addressesMinted[_msgSender()]) {
            revert WalletAlreadyMinted();
        }

        if(phase1.isOpen) {
            currentPhase = mintPhases[1];
        }
        else {
            currentPhase = mintPhases[2];
        }

        if(currentPhase.numMinted + 1 > currentPhase.supply) {
            revert MaxSupplyOfPhaseReached();
        }

        _addressesMinted[_msgSender()] = true;
        currentPhase.numMinted++;

        CBDCToken.safeTransferFrom(_msgSender(), currentPhase.beneficiary, currentPhase.price);
        _mint(_msgSender(), 1);
    }

    /// @notice Opens/closes the mint phase of the Central Bro's Inner Circle.
    function flipMintPhase(uint256 phase) external onlyOwner {
        if(phase != 1 && phase != 2) {
            revert InvalidMintPhase();
        }

        MintPhase storage mintPhase = mintPhases[phase];
        mintPhase.isOpen = !mintPhase.isOpen;
    }

    function setMintPhasePrice(uint256 phase, uint256 price) external onlyOwner {
        if(phase != 1 && phase != 2) {
            revert InvalidMintPhase();
        }

        MintPhase storage mintPhase = mintPhases[phase];
        mintPhase.price = price;
    }

    function teamMint(address beneficiary) external onlyOwner {
        require(beneficiary != address(0), 'invalid address');

        if(_hasTeamMinted) {
            revert TeamMintAlreadyComplete();
        }

        _hasTeamMinted = true;
        _mint(beneficiary, TEAM_SUPPLY);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseUri = uri;
    }

    function getReceivedBlock(address account) external view returns(uint256) {
        return _receivedBlock[account];
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual override {
        if (_receivedBlock[to] == 0) {
            _receivedBlock[to] = block.number;
        }

        if(from != address(0) && balanceOf(from) == 1) {
            _receivedBlock[from] = 0;
        }
        
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
    
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @dev Both safeTransferFrom functions in ERC721A call this function
     * so we don't need to override them.
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}