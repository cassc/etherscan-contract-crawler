// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error NotOwner();
error NotEnoughETH(uint256 value);
error FailedRefundingSurplus(uint256 value);
error NotStarted();
error AlreadyStarted();
error AlreadyEnded();
error SendingFailed();
error NotWhitelisted(address minter);
error NoTokensReservedForMinter(address minter);
error AlreadyMinted(address minter);
error ClaimNotStarted();
error MintCapReached();

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract PandorasBox is ERC721, ReentrancyGuard {
    event Minted(address minter, uint256 id);
    event MetadataUpdate();
    event MintPhase();
    event EndMintPhase();
    /* State variables */
    bool public started = false;
    bool public ended = false;
    /* State variables */

    address public owner;
    uint256 public cost = 0.22 ether;

    uint256 public immutable cap = 555;
    uint256 public mintCount = 0;
    mapping(address => bool) public mints;

    uint256 public whitelistOnly = 2 hours;
    uint256 public startTime;

    bytes32 public immutable merkleRoot;

	string internal tokenMetadataURI;
    constructor(address multisig, bytes32 _merkleRoot)
        ERC721("Pandora's Box", "BOX")
    {
        owner = multisig;
        merkleRoot = _merkleRoot;


        for (uint256 index = 0; index < 55; index++) {
			mintCount++;
            _safeMint(multisig, mintCount);
        }
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /* NFT Functionality */
	function setTokenMetadata(string calldata newMetadata) public onlyOwner {
		tokenMetadataURI = newMetadata;
		emit MetadataUpdate();
	}

    function tokenURI(uint256)
        public
        view
        override
        returns (string memory)
    {
        return tokenMetadataURI;
    }
    /* NFT Functionality */

	/* Sale */
    function start() external onlyOwner {
        if (started == true) revert AlreadyStarted();
        started = true;
        startTime = block.timestamp;

        emit MintPhase();
    }
    function canMint(address minter, bytes32[] calldata proof)
        public
        view
        returns (bool)
    {
        if (started == false) return false;
        bool proofValid = MerkleProof.verify(
            proof,
            merkleRoot,
            keccak256(abi.encodePacked(minter))
        );

        if (
            proofValid &&
            ((block.timestamp - startTime) < whitelistOnly)
        ) return true;

        if (((block.timestamp - startTime) > whitelistOnly))
            return true; 

        return false;
    }
    function mint(bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
    {
        if (started == false) revert NotStarted();
        if (ended == true) revert AlreadyEnded();
        if (!canMint(msg.sender, merkleProof)) revert NotWhitelisted(msg.sender);
        if (msg.value < cost) revert NotEnoughETH(msg.value);
        if (mintCount >= cap) revert MintCapReached();
        if (mints[msg.sender]) revert AlreadyMinted(msg.sender);

        mintCount++;
        mints[msg.sender] = true;


		/* refund the user for everything above cost */
        uint256 remainingETH = msg.value - cost;
        if (remainingETH > 0) {
            (bool sent, ) = msg.sender.call{value: remainingETH}("");
            if (!sent) revert FailedRefundingSurplus(remainingETH);
        }

        _safeMint(msg.sender, mintCount);
        emit Minted(msg.sender, mintCount);
    }
    function finish() external onlyOwner {
        if (ended == true) revert AlreadyEnded();
        ended = true;

        emit EndMintPhase();
    }

	function mintRemainer() external onlyOwner {
		/* Mint remaining to multisig */
        for (uint256 index = mintCount; index < cap; index++) {
			mintCount++;
            _safeMint(owner, mintCount);
        }
	}
	/* Sale */


	/* Recovery functions */
    function recoverETH() external onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        if (!sent) revert SendingFailed();
    }

    function recoverERC20(IERC20 _token) external onlyOwner {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }
	/* Recovery functions */

	fallback() external payable {}
	receive() external payable {}
}