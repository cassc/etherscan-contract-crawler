pragma solidity 0.6.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev VoguNFTBase contract.
 * @notice Setup admin control functional, include MINT_FEE_PER_TOKEN, Total Supply and metadata proven hash
 */
contract VoguNFTBase is Ownable, ERC721 {
    uint256 public constant LIMIT_TOKEN_PER_TX = 17;

    uint256 public MAX_VOGU;
    uint256 public MINT_FEE_PER_TOKEN;

    bytes32 public proven;

    // status = false <=> contract offline
    // status = true <=> contract online
    // token only can mint when contract online
    // admin only can setup contract when contract offline
    bool public status;

    /**
     * @param _mintFeePerToken The Fee (in ETH) collector/user pays for Vogu when one token is minted.
     * @param _MAX_VOGU Total supply of contract
     */
    constructor(uint256 _mintFeePerToken, uint256 _MAX_VOGU)
        public
        ERC721("Vogu", "VGT")
    {
        MAX_VOGU = _MAX_VOGU;
        MINT_FEE_PER_TOKEN = _mintFeePerToken;
    }

    /**
     * @dev ensure contract is online
     */
    modifier online() {
        require(status, "Contract must be online.");
        _;
    }

    /**
     * @dev ensure contract is offline
     */
    modifier offline() {
        require(!status, "Contract must be offline.");
        _;
    }

    /**
     * @dev ensure collector pays for mint token
     */
    modifier mintable(uint256 numberToken) {
        require(numberToken <= LIMIT_TOKEN_PER_TX, "Number Token invalid");
        require(msg.value >= numberToken.mul(MINT_FEE_PER_TOKEN), "Payment error");
        _;
    }

    /**
     * @dev change status from online to offline and vice versa
     */
    function toggleActive() public onlyOwner returns (bool) {
        status = !status;
        return true;
    }

    // TODO: should set fix MINT_FEE_PER_TOKEN
    function setMintFee(uint256 _mintFeePerToken)
        public
        onlyOwner
        offline
        returns (bool)
    {
        MINT_FEE_PER_TOKEN = _mintFeePerToken;
        return true;
    }

    /**
     * @dev Set base URI for contract
     * @param _baseURI ipfs hash
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    /**
     * @dev withdraw ether to owner/admin wallet
     * @notice ONLY owner can call this function
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     * @dev Set proven hash of metadata
     */
    function provenHash(bytes32 _proven) public onlyOwner {
        proven = _proven;
    }
}