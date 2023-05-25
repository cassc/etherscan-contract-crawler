// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
    @notice IMPORTANT NOTICE:
    This smart contract was written and deployed by the software engineers at
    https://horagames.com in a contractor capacity.

    HoraGames is not responsible for any malicious use or losses arising from using
    or interacting with this smart contract.

    THIS CONTRACT IS PROVIDED ON AN “AS IS” BASIS. USE THIS SOFTWARE AT YOUR OWN RISK.
    THERE IS NO WARRANTY, EXPRESSED OR IMPLIED, THAT DESCRIBED FUNCTIONALITY WILL
    FUNCTION AS EXPECTED OR INTENDED. PRODUCT MAY CEASE TO EXIST. NOT AN INVESTMENT,
    SECURITY OR A SWAP. TOKENS HAVE NO RIGHTS, USES, PURPOSE, ATTRIBUTES,
    FUNCTIONALITIES OR FEATURES, EXPRESS OR IMPLIED, INCLUDING, WITHOUT LIMITATION, ANY
    USES, PURPOSE OR ATTRIBUTES. TOKENS MAY HAVE NO VALUE. PRODUCT MAY CONTAIN BUGS AND
    SERIOUS BREACHES IN THE SECURITY THAT MAY RESULT IN LOSS OF YOUR ASSETS OR THEIR
    IMPLIED VALUE. ALL THE CRYPTOCURRENCY TRANSFERRED TO THIS SMART CONTRACT MAY BE LOST.
    THE CONTRACT DEVELOPERS ARE NOT RESPONSIBLE FOR ANY MONETARY LOSS, PROFIT LOSS OR ANY
    OTHER LOSSES DUE TO USE OF DESCRIBED PRODUCT. CHANGES COULD BE MADE BEFORE AND AFTER
    THE RELEASE OF THE PRODUCT. NO PRIOR NOTICE MAY BE GIVEN. ALL TRANSACTION ON THE
    BLOCKCHAIN ARE FINAL, NO REFUND, COMPENSATION OR REIMBURSEMENT POSSIBLE. YOU MAY
    LOOSE ALL THE CRYPTOCURRENCY USED TO INTERACT WITH THIS CONTRACT. IT IS YOUR
    RESPONSIBILITY TO REVIEW THE PROJECT, TEAM, TERMS & CONDITIONS BEFORE USING THE
    PRODUCT.

**/
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


/** @title BLVCK NFT Contract
 * @author Dr. Siniša
 * @notice This contract follows ERC721 standard. It's extended with OpenZeppelin's 'Ownable' library
 * which controls what methods can be called exclusively by contract's owner and eventually allows the current owner
 * to transfer ownership to someone else. see https://docs.openzeppelin.com/contracts/2.x/access-control for details.
 * It also includes 'PaymentSplitter' functions which enables the shareholders to withdraw funds from this contract,
 * also including any tokens received. see https://docs.openzeppelin.com/contracts/2.x/api/payment for more.
 * Token IDs are always ordered from 0 to totalSupply(). No 'gaps' and no 'Burned' tokens are possible.
 *   The contract Owner can enable and disable Public Sale which, when enabled, allows tokens to be minted by
 * everyone if the right amount of funds is provided to 'safeMint' method.
 * Price for minting a token can be changed at any time by the Owner, but there is only one price for all tokens
 * at a time. Server base url can be changed if someday maybe NFT metadata will migrate to IPFS or another server/domain.
 *    An address can be assigned by Owner to be 'minter'. That account would normally be controlled
 * by backend to allow more control over minting process, whitelisting, raffle, and would make significant reduction
 * in gas costs. When a user is added to whitelist by raffle or operators, he can then deposit funds to this
 * contract and then wait to be verified by minter service, which will eventually mint NFT(s) to user. Each user has
 * total deposit value stored in this contract, and after received a certain amount of NFTs, that value resets to zero.
 */
contract BLVCKNFT is ERC721, Ownable, PaymentSplitter {
    using Counters for Counters.Counter;

    /**
     * @notice constant limit for tokens total supply. cannot be changed by anyone
     */
    uint256 private constant MAX_SUPPLY = 9999;
    uint256 private constant RESERVED_AMOUNT = 300;
    /**
     * @notice switch on/off public sale
     */
    bool private publicSaleIsActive = false;
    /**
     * @notice address assigned to control minting
     */
    address private minterAddress;
    bool private minterEnabled;
    /**
     * @notice universal url prefix for all NFTs in this contract, so the final url is like baseUri + '/' + token id
     */
    string private baseUri;
    /**
     * @notice current price to mint single NFT
     */
    uint256 private currentPrice = 0.2 ether;
    /**
     * @notice counter to assign next token id (this equals totalSupply)
     */
    Counters.Counter private _tokenIdCounter;
    /**
     * @notice list of addresses that deposited funds, waiting to receive tokens. when zero or less than current price, no minting will happen.
     */
    mapping(address => uint256) private pendingMintBalances;

    /**
     * @notice initialization of contract
     * @dev checkout https://docs.openzeppelin.com/contracts/2.x/api/payment on how to configure _payees and _shares
     * @param payeesList is a list of shareholders
     * @param sharesList is a list of shares belonging to shareholders at corresponding index in _payees list
     */
    constructor(address[] memory payeesList, uint256[] memory sharesList)
    ERC721("Blvck Genesis", "Blvck")
    PaymentSplitter(payeesList, sharesList) {
    }

    function setBaseUri(string calldata newBaseURI) external onlyOwner {
        baseUri = newBaseURI;
    }

    function setPublicSale(bool setPublicSaleIsActive) external onlyOwner {
        publicSaleIsActive = setPublicSaleIsActive;
    }

    function setMinterAddress(address newMinterAddress) external onlyOwner{
        minterAddress = newMinterAddress;
    }

    function setCurrentPrice(uint256 newPrice) external onlyOwner {
        currentPrice = newPrice;
    }

    function setMinterEnabled(bool enabled) external onlyOwner {
        minterEnabled = enabled;
    }

    /**
     * @notice functions with this modifier are only allowed to be executed by minter account
     */
    modifier onlyMinter() {
        require(minterAddress == _msgSender() && minterAddress != address (0), "not a minter");
        _;
    }

    modifier onlyMinterAndEnabled() {
        require(minterAddress == _msgSender() && minterAddress != address (0), "not a minter");
        require(minterEnabled, "enable minter first");
        _;
    }

    /**
     * @notice functions with this modifier work when public sale is active
     */
    modifier onlyOnPublicSale() {
        require(publicSaleIsActive, "public sale is not active");
        _;
    }

    /**
     * @notice checking for price match and that total supply would be reached
     * @param value is a total amount user is trying to send
     * @param amount is how many tokens user wants to mint
     * @return uint256 tokenId
     */
    function checkPriceAndAmount(uint256 value, uint256 amount) private view returns (uint256) {
        require(amount > 0 && value == currentPrice * amount, "invalid price");
        return checkTotalSupply(amount);
    }

    /**
     * @notice check if total supply would overflow for amount of new tokens
     * @param amount is how many tokens user wants to mint
     * @return uint256 tokenId
     */
    function checkTotalSupply(uint256 amount) private view returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId + amount < MAX_SUPPLY - RESERVED_AMOUNT, "no more tokens available for minting");
        return tokenId;
    }

    function checkTotalSupply(uint256 amount, bool useReservedAmount) private view returns (uint256) {
        if (!useReservedAmount) {
            return checkTotalSupply(amount);
        }
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId + amount < MAX_SUPPLY, "total supply reached");
        return tokenId;
    }

    ////////////////////////////////////////// Mint Functions //////////////////////////////////////////////////////

    /**
     * @notice ERC721 compatible mint method. exact amount of funds must be sent when calling this function (currentPrice * amount)
     * @notice everyone can execute but only if public sale is active
     * @param amount is how much NFTs is expected to mint. will fail if amount is zero or does not match with currentPrice total
     */
    function safeMint(uint256 amount) external payable onlyOnPublicSale {
        uint256 tokenId = checkPriceAndAmount(msg.value, amount);
        safeMintMany(_msgSender(), tokenId, amount);
    }

    /**
     * @notice mint amount of tokens
     * @param to is the address to receive tokens
     * @param tokenId is the starting id of token
     * @param amount is how many tokens to mint
     */
    function safeMintMany(address to, uint256 tokenId, uint256 amount) private {
        for (uint i = 0; i < amount; ++i) {
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
            tokenId = _tokenIdCounter.current();
        }
    }

    /**
     * @notice this allows minter account to mint amount of tokens for addresses
     * @param amount is number of tokens to mint for address at same index
     * @param addresses is accounts receiving the tokens
     */
    function minterMintBatch(uint256 amount, address[] calldata addresses) external onlyMinterAndEnabled {
        uint256 tokenId = checkTotalSupply(amount * addresses.length, true);
        uint256 i;
        for (i = 0; i < addresses.length; i++) {
            uint256 j;
            address to = addresses[i];
            for (j = 0; j < amount; j++) {
                _tokenIdCounter.increment();
                _safeMint(to, tokenId);
                tokenId = _tokenIdCounter.current();
            }
        }
    }

    /**
     * @notice this allows minter account to mint one token for address to
     * @param to is account receiving the tokens
     */
    function minterMint(address to) external onlyMinterAndEnabled {
        uint256 tokenId = checkTotalSupply(1, true);
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
    }

    /**
     * @notice this is executed by minter to settle balance of user deposited to contract and increase balance of NFTs to user
     * @param addresses is the account(s) to receive NFTs (if deposited enough funds)
     */
    function minterMintWithPendingBalance(address[] memory addresses) external onlyMinterAndEnabled {
        uint256 tokenId = checkTotalSupply(addresses.length);
        uint256 i;
        for (i = 0; i < addresses.length; i++) {
            address to = addresses[i];
            if (pendingMintBalances[to] >= currentPrice) {
                _tokenIdCounter.increment();
                pendingMintBalances[to] -= currentPrice;
                _safeMint(to, tokenId);
                tokenId = _tokenIdCounter.current();
            }
        }
    }

    /**
     * @notice this allows Owner to mint some tokens to himself only paying for gas price
     * @param amount is number of tokens to mint
     */
    function reserveTokens(address to, uint256 amount) external onlyOwner() {
        uint256 tokenId = checkTotalSupply(amount, true);
        safeMintMany(to, tokenId, amount);
    }

    /**
    * Function to clear the Pending balance for some addresses
    */
    function clearPendingBalances(address[] memory addresses) external onlyMinterAndEnabled {
        uint256 i;
        for (i = 0; i < addresses.length; i++) {
            address to = addresses[i];
            pendingMintBalances[to] = 0;
        }
    }

    /**
    * Function to refund pending balance for some address
    */
    function refundPendingBalance(uint256 amount, address payable to) external onlyOwner {
        require(pendingMintBalances[to] >= amount, "amount > balance");
        pendingMintBalances[to] -= amount;
        to.transfer(amount);
    }


    ////////////////////////////////////////// View Functions //////////////////////////////////////////////////////

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function baseURI() external view returns (string memory) {
        return baseUri;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseUri, "contract"));
    }

    /**
     * @notice query who currently is a minter (public)
     * @return address of minter
     */
    function getMinterAddress() external view returns (address){
        return minterAddress;
    }

    /**
     * @notice query for current mint price (public)
     * @return uint256 price in wei
     */
    function getCurrentPrice() external view returns (uint256){
        return currentPrice;
    }

    /**
     * @notice check how much funds some address has deposited (public)
     * @param addressToCheck is to specify account
     * @return uint256 amount of funds deposited by address waiting to receive NFTs. multiple deposits are added. balance can be reset to zero by minter
     */
    function readPendingMintBalance(address addressToCheck) external view returns (uint256) {
        return pendingMintBalances[addressToCheck];
    }

    /**
     * @notice batch query to check a list of addresses for deposit balance (public)
     * @param addresses is a list of addresses to check for balance
     * @return uint256 amount of funds deposited by address waiting to receive NFTs. multiple deposits are added. balance can be reset to zero by minter
     */
    function readPendingMintBalanceBatch(address[] memory addresses) external view returns (uint256 [] memory) {
        uint256 [] memory balances = new uint256[](addresses.length);
        for (uint i = 0; i < addresses.length; ++i) {
            balances[i] = pendingMintBalances[addresses[i]];
        }
        return balances;
    }

    /**
     * @notice get current amount of tokens minted
     * @return uint256 amount of tokens
     */
    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /*
        just a wrapper to make try/catch block working
    */
    function ownerOfTokenExternal(uint256 tokenId) external view returns (address) {
        return ownerOf(tokenId);
    }
    /**
     * @notice extension to erc721 ownerOf, to support batch request and lower API calls to blockchain node
     * @param start is the starting token index
     * @param count is how many consecutive tokens to return
     * @return uint256 array of owners of tokens with offset relative to start
     */
    function ownerOfBatch(uint256 start, uint256 count) external view returns (address [] memory) {
        address [] memory owners = new address[](count);
        for (uint i = 0; i < count; ++i) {
            uint256 tokenId = start + i;
            if (tokenId > _tokenIdCounter.current()) {
                owners[i] = address (0);
            } else {
                try this.ownerOfTokenExternal(tokenId) returns (address tokenOwner) {
                    owners[i] = tokenOwner;
                } catch Error(string memory /*reason*/) {
                    owners[i] = address (0);
                }
            }
        }
        return owners;
    }

    ////////////////////////////////////////// Whitelist Functions //////////////////////////////////////////////////////

    /*
        this is to control how much some whitelisted address can mint per round
        in round 1 amount is max 1, round 2 max 1, round 3 is currently unlimited but it's just for testing
    */
    mapping(address => bool) private claimedInRound1;
    mapping(address => bool) private claimedInRound2;

    /* this is set when round is set */
    bytes32 private merkleRoot = "";

    /* everything disabled by default */
    uint256 currentRound = 0;

    /* will be used by backend to start issuing proofs to clients */
    function getCurrentRound() external view returns (uint256) {
        return currentRound;
    }

    /* we may show this on frontend mint page ? */
    function getClaimedAmounts(address addr) external view returns (bool, bool) {
        return (claimedInRound1[addr], claimedInRound2[addr]);
    }

    /*
        we will call this from backend, when configuration is changed manually at run time
    */
    function setCurrentRound(uint256 newCurrentRound, bytes32 newMerkleRoot) external onlyMinter {
        currentRound = newCurrentRound;
        merkleRoot = newMerkleRoot;
    }

    /*
        main mint function to be called from frontend
        proof if obtained from backend endpoint if signature is verified and canMint=1
    */
    function whitelistMint(bytes32[] calldata merkleProof) external payable {
        require(currentRound > 0 && currentRound < 4, "currentRound must be 1-3");
        require(msg.value == currentPrice, "exact amount of ETH must be sent");
        uint256 tokenId = checkTotalSupply(1);

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "invalid proof, you are not blvcklisted");

        if (currentRound == 1) {
            require(!claimedInRound1[_msgSender()], "maximum is 1 mint in round 1");
            claimedInRound1[_msgSender()] = true;
        } else if (currentRound == 2) {
            require(!claimedInRound2[_msgSender()], "maximum is 1 mint in round 2");
            claimedInRound2[_msgSender()] = true;
        }

        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);
    }


    ////////////////////////////////////////// Payment Functions //////////////////////////////////////////////////////


    /**
     * @notice this gets called when whitelisted user sends funds to this contract
     */
    receive() external payable virtual override { // override from PaymentSplitter
        pendingMintBalances[_msgSender()] += msg.value; // add new funds to users pendingBalance record
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /*
        because etherscan fails to call overloaded release function
    */
    function release2(address payable addr) external {
        release(addr);
    }
}