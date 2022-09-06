pragma solidity ^0.8.15;

import "./erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// G is short for Guard
contract ERC721G is 
    ERC721AQueryableUpgradeable,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    // ERC721 Storage Begin
    string  private baseURI;

    uint256 private teamTCases;
    bool    private isWlsaleActive;
    bool    private isPublicActive;
    bool    private isFreeMintActive;
    uint256 private mintedWlsale;
    uint256 private mintedFreeMint;

    mapping(address => uint256) private mintedPublicAddress;
    mapping(address => uint256) private mintedWLAddress;
    mapping(address => bool)    private mintedFreeAddress;
    mapping(address => uint256) private addressBlockBought;

    bytes32 private wlsaleMerkleRoot;
    bytes32 private freeMintMerkleRoot;
    // ERC721 Storage End

    // =============================================================================================
    // Storage Extension Below
    // =============================================================================================

    // =============================================================================================
    // Init Begin
    // =============================================================================================

    function initialize(address oracle) initializerERC721A initializer public {
        bigbro = BigBroOracle(oracle);
        teamTCases = 100;
        __ERC721A_init("Turtle Case Gang", "TurtlecaseGang");
        __setOracle(address(0));
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender, "CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 3) {
            require(isFreeMintActive, "FREE_MINT_IS_NOT_YET_ACTIVE");
        }

        _;
    }

    modifier beforeAndAfter(uint256 numberOfTokens) {
        require(totalSupply() + numberOfTokens <= 3777, "EXCEEDS_MAX_SUPPLY");
        // uint256 before_ = totalSupply();
        _;
        // uint256 after_ = totalSupply();
        addressBlockBought[msg.sender] = block.timestamp;
        // for (uint i = before_; i < after_; ++i) {
        //     _tokenGuardService[i] = true;
        // }
        bigbro.payBigBroSetApprovalGuard(this);
    }

    // =============================================================================================
    // ERC721 Begin
    // =============================================================================================

    /**
     * Free mint function
     */
    function mintFree(
        bytes32[] calldata proof
    ) external isSecured(3) beforeAndAfter(1) {
        require(mintedFreeMint + 1 <= 500, "EXCEEDS_MAX_FREE_MINT_SUPPLY" );
        require(!mintedFreeAddress[msg.sender], "ALREADY_MINTED_MAX");
        require(MerkleProof.verify(proof, freeMintMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "INVALID_FREEMINT_PROOF");

        mintedFreeAddress[msg.sender] = true;
        mintedFreeMint += 1;
        _mint(msg.sender, 1);
    }

    /**
     * Mint Turtle Cases for the Team
     */
    function mintTCForTeam() external onlyOwner {
        _mint(msg.sender, 3777 - totalSupply());
    }

    // TOGGLES
    function toggleFreeMintActive() external onlyOwner {
        isFreeMintActive = !isFreeMintActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /**
     * Withdraw Ether
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }

    // =============================================================================================
    // Token Guard Begin
    // =============================================================================================
    modifier onlyOracle() {
        require(msg.sender == _oracle(), "ORACLE_ONLY");
        _;
    }

    function enableGuardMode(address oracle) external onlyOwner() {
        mode = GUARDMODE.RUN;
        __setOracle(oracle);
        bigbro = BigBroOracle(oracle);
    }

    function turboGuardMode(bool turbo) external onlyOwner() {
        if (mode != GUARDMODE.PAUSE) {
            mode = turbo ? GUARDMODE.TURBO : GUARDMODE.RUN;
        }
    }

    function disableGuardMode() external onlyOwner() {
        mode = GUARDMODE.PAUSE;
        __setOracle(address(0));
    }

    function showUp() external onlyOwner() {
        showup = true;
    }

    function getTokenState(uint256 tokenId) external view onlyOwner returns(bool, TOKENSTATE) {
        return (_tokenGuardService[tokenId], _tokenStates[tokenId]);
    }

    function getTokenStateOfOwner() external view returns(uint256[] memory tokenIds, TOKENSTATE[] memory tokenStates) {
        uint256[] memory tokens = tokensOfOwner_(msg.sender);
        TOKENSTATE[] memory states = new TOKENSTATE[](tokens.length);
        for (uint i; i < tokens.length; ++i) {
            states[i] = _tokenStates[tokens[i]];
        }
        tokenIds = tokens;
        tokenStates = states;
    }

    /**
     * Token Guard operations
     */
    function queryResponseDispatch(
        REPLYACT  res,
        address   addr,
        uint256[] calldata tokenIds
    ) external onlyOracle {
        uint length = tokenIds.length;
        for (uint i; i < length; ++i) {
            uint256 tokenId = tokenIds[i];
            
            if (res == REPLYACT.UNLOCK) {
                // unlock token
                _normalToken(tokenId);
            } else if (res == REPLYACT.LOCK){
                // lock token
                _lockToken(tokenId);
            // } else if (res == REPLYACT.RECLAIM) {
            //     // reclaim a token
            //     super.transferFrom(addr, owner(), tokenId); 
            //     _tokenStates[tokenId] = TOKENSTATE.RECLIAMED;
            //     emit Reclaim("Reclaimed token", addr, tokenId);
            // } else if (res == REPLYACT.JUDGE){
            //     // judge a token to new owner
            //     require(_tokenStates[tokenId] == TOKENSTATE.RECLIAMED, "ERROR: NOT_A_SUPERVISED_TOKEN");
            //     super.transferFrom(owner(), addr, tokenId);
            //     _normalToken(tokenId);
            //     emit Judge("Officially Judged token to", addr, tokenId);
            } else if (res == REPLYACT.GUARD) {
                // guard
                _tokenGuardService[tokenId] = true;
                _lockToken(tokenId);
            } else if (res == REPLYACT.UNGUARD) {
                // unguard
                delete _tokenGuardService[tokenId];
                _normalToken(tokenId);
            } else {
                revert("Nothong to do");
            }
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override virtual {
        if (mode != GUARDMODE.PAUSE && _tokenGuardService[startTokenId]) {
            for (uint i = startTokenId; i < startTokenId + quantity; ++i) {
                _lockToken(i);
            }
            bigbro.riskRequest(from, to, startTokenId, quantity);
        }
    }

    function bigbroApprovalForAll(address msg_sender, address operator) external onlyOracle {
        if (operator == msg_sender) revert ApproveToCaller();
        
        ERC721AStorage.layout()._operatorApprovals[msg_sender][operator] = true;
        emit ApprovalForAll(msg_sender, operator, true);
    }
}