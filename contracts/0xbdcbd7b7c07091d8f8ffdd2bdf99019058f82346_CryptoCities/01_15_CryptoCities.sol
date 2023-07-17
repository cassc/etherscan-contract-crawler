//      ___                     _            ___  _  _    _            
//     / __\_ __  _   _  _ __  | |_  ___    / __\(_)| |_ (_)  ___  ___ 
//    / /  | '__|| | | || '_ \ | __|/ _ \  / /   | || __|| | / _ \/ __|
//   / /___| |   | |_| || |_) || |_| (_) |/ /___ | || |_ | ||  __/\__ \
//   \____/|_|    \__, || .__/  \__|\___/ \____/ |_| \__||_| \___||___/
//                |___/ |_|                                            
//
// CryptoCities is an ERC721 compliant smart contract for this project:
// (https://cryptocities.net)  
//
// In addition to a standard ERC721 interface it also includes:
//  - a maker / taker off-chain marketplace which executes final trades here
//  - batch functions for most token read functions
//  - a limited supply of 25000 tokens
// 
//  Discord:
//   https://discord.gg/Y4mhwWg 
//
//  Bug Bounty:
//   Please see the details of our bug bounty program below.  
//   https://cryptocities.net/bug_bounty
//
//  Disclaimer:
//   We take the greatest of care when making our smart contracts but this is crypto and the future 
//   is always unknown. Even if it is exciting and full of wonderful possibilities, anything can happen,  
//   blockchains will evolve, vulnerabilities can arise, and markets can go up and down. CryptoCities and its  
//   owners accept no liability for any issues relating to the use of this contract or any losses that may occur. 
//   Please see our full terms here: 
//   https://cryptocities.net/terms


// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./base/ERC721Batchable.sol";

contract CryptoCities is ERC721Batchable 
{
    // there can only ever be a max of this many tokens in the contract
    uint public constant tokenLimit = 25000;

    // the base url used for all meta data 
    // likely to be stored on IPFS over time   
    string private _baseTokenURI;

    // the opensea proxy registry contract (can be changed if this registry ever moves to a new contract)
    // 0xa5409ec958C83C3f309868babACA7c86DCB077c1  mainnet
    // 0xF57B2c51dED3A29e6891aba85459d600256Cf317  rinkeby
    // 0x0000000000000000000000000000000000000000  local
    address private _proxyRegistryAddress;

    // only authorized minters can mint tokens
    // this will originally be set to a swapping contract to allow users to swap their tokens to this new contract 
    mapping (address => bool) public isMinter;    

    // pausing the market disables the built-in maker/taker offer system 
    // it does not affect normal ERC721 transfers 
    bool public marketPaused;

    // the marketplace fee for any internal paid trades (stored in basis points eg. 250 = 2.5% fee) 
    uint16 public marketFee;

    // the marketplace witness is used to validate marketplace offers 
    address private _marketWitness;

    // offer that can no longer be used any more
    mapping (bytes32 => bool) private _cancelledOrCompletedOffers;

    // support for ERC2981
    uint16 private _royaltyFee;
    address private _royaltyReciever;

    constructor(address _owner, address _recovery, address proxyRegistryAddress) ERC721("CryptoCities", unicode"⬢City")    
    {
        // set the owner, recovery & treasury addresses
        transferOwnership(_owner);
        treasury = _owner;
        recovery = _recovery;

        // set the meta base url
        _baseTokenURI = "https://cryptocities.net/meta/";

        // set the open sea proxy registry address
        _proxyRegistryAddress = proxyRegistryAddress;

        // market starts disabled
        marketPaused = true;       
        marketFee = 250;    
    }


    /// BASE URI

    // base uri is where the metadata lives
    // only the owner can change this

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function contractURI() public pure returns (string memory) {
        return "https://cryptocities.net/meta/cities_contract";
    }

    /// PROXY REGISTRY

    // registers a proxy address for OpenSea or others
    // can only be changed by the contract owner
    // setting address to 0 will disable the proxy 

    function setProxyRegistry(address proxyRegistry) external onlyOwner { 

        // check the contract address is correct (will revert if not)
        if(proxyRegistry!= address(0)) {
            ProxyRegistry(proxyRegistry).proxies(address(0));
        }

        _proxyRegistryAddress = proxyRegistry;    
    }

    // this override allows us to whitelist user's OpenSea proxy accounts to enable gas-less listings
    function isApprovedForAll(address token_owner, address operator) public view override returns (bool)
    {
        // whitelist OpenSea proxy contract for easy trading.
        if(_proxyRegistryAddress!= address(0)) {
            ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
            if (address(proxyRegistry.proxies(token_owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(token_owner, operator);
    }


    /// MINTING

    // only authorized minters can mint
    // can't mint more tokens than the token limit
    
    // ERC721 standard checks:
    // can't mint while the contract is paused (checked in _beforeTokenTransfer())
    // token id's can't already exist 
    // cant mint to address(0)
    // if 'to' refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.

    // emitted when a minter's authorization changes
    event MinterSet(address indexed minter, bool auth);

    // only allows an authorized minter to call the function
    modifier onlyMinters() 
    {
        require(isMinter[_msgSender()]==true, "caller not a minter");
        _;
    }

    // changes a minter's authorization
    function setMinter(address minter, bool authorized) external onlyOwner 
    { 
        isMinter[minter] = authorized;        
        emit MinterSet(minter, authorized);        
    }

    // mint a single token
    function mint(address to, uint256 tokenId) external onlyMinters  
    {        
        require(totalSupply()<tokenLimit, "token limit reached");
        _safeMint(to, tokenId);
    }

    // mint a batch of tokens
    // (gas: this function can run out of gas if too many id's are provided
    //       limiting to 25 will currently fit in the block gas limit but this may change in future)
    function mintBatch(address to, uint256[] memory tokenIds) external onlyMinters     
    {       
        require(tokenIds.length <= 25, "more than 25 ids");
        require(totalSupply()+tokenIds.length <= tokenLimit, "batch exceeds token limit");

        for (uint256 i = 0; i < tokenIds.length; i++) {  
            // we safe mint the first token          
            if(i==0) _safeMint(to, tokenIds[i]);

            // then we assume the rest are safe because they are going to the same receiver  
            else _mint(to, tokenIds[i]);      
        }         
    }

    /// BURNING

    // only the contract owner can burn tokens it owns
    // the contract owner can't burn someone elses tokens
    // normal users can't burn tokens

    // ERC721 standard checks:
    // can't burn while the contract is paused (checked in _beforeTokenTransfer())
    // the token id must exist

    function burn(uint256 tokenId) external onlyOwner 
    {
         require(ownerOf(tokenId) == owner(), "token owner not contract owner");
        _burn(tokenId);
    }


    /// MARKETPLACE

    // this contract includes a maker / taker offerplace
    // (similar to those seen in OpenSea, 0x Protocol and other NFT projects) 
    //
    // offers are made by makers off-chain and filled by callers on-chain
    // makers do this by signing their offer with their wallet 
    // smart contracts can't be makers because they can't sign messages
    // if a witness address is set then it must sign the offer hash too (eg. the website marketplace)

    // there are two types of offers depending on whether the maker specifies a taker in their offer:
    // maker / taker       (peer-to-peer offer:  two users agreeing to trade items)
    // maker / no taker    (open offer:  one user listing their items in the marketplace)

    // if eth is paid then it will always be on the taker side (the maker never pays eth in this simplified model)
    // a market fee is charged if eth is paid
    // trading tokens with no eth is free and no fee is deducted

    // allowed exchanges:

    //   maker tokens  > <  eth                          (maker sells their tokens to anyone)
    //   maker tokens  >                                 (maker gives their tokens away to anyone)

    //   maker tokens  >    taker                        (maker gives their tokens to a specific taker)
    //   maker tokens  > <  taker tokens                     .. for specific tokens back
    //   maker tokens  > <  taker tokens & eth               .. for specific tokens and eth back 
    //   maker tokens  > <  taker eth                        .. for eth only

    //   maker           <  taker tokens                 (taker gives their tokens to the maker)
    //   maker           <  taker tokens & eth               .. and with eth    

    event OfferAccepted(bytes32 indexed hash, address indexed maker, address indexed taker, uint[] makerIds, uint[] takerIds, uint takerWei, uint marketFee);    
    event OfferCancelled(bytes32 indexed hash);
    
    struct Offer {
        address maker;
        address taker;
        uint256[] makerIds;        
        uint256[] takerIds;
        uint256 takerWei;
        uint256 expiry;
        uint256 nonce;
    }

    // pausing the market will stop offers from being able to be accepted (they can still be generated or cancelled)
    function pauseMarket(bool pauseTrading) external onlyOwner {
        marketPaused = pauseTrading;
    }

    // the market fee is set in basis points (eg. 250 basis points = 2.5%)
    function setMarketFee(uint16 basisPoints) external onlyOwner {
        require(basisPoints <= 10000);
        marketFee = basisPoints;
    }

    // if a market witness is set then it will need to sign all offers too (set to 0 to disable)
    function setMarketWitness(address newWitness) external onlyOwner {
        _marketWitness = newWitness;
    }

    // recovers the signer address from a offer hash and signature
    function signerOfHash(bytes32 offer_hash, bytes memory signature) public pure returns (address signer){
        require(signature.length == 65, "sig wrong length");

        bytes32 geth_modified_hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", offer_hash));
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "bad sig v");

        return ecrecover(geth_modified_hash, v, r, s);
    }
 

    // this generates a hash of an offer that can then be signed by a maker
    // the offer has to have basic validity before it can be hashed
    // if checking ids then the tokens need to be owned by the parties too 
    function hashOffer(Offer memory offer, bool checkIds) public view returns (bytes32){

        // the maker can't be 0
        require(offer.maker!=address(0), "maker is 0");

        // maker and taker can't be the same
        require(offer.maker!=offer.taker, "same maker / taker");

        // the offer must not be expired yet
        require(block.timestamp < offer.expiry, "expired");

        // token id must be in the offer
        require(offer.makerIds.length>0 || offer.takerIds.length>0, "no ids");

        // if checking ids then maker must own the maker token ids
        if(checkIds){
            for(uint i=0; i<offer.makerIds.length; i++){
                require(ownerOf(offer.makerIds[i])==offer.maker, "bad maker ids");
            }
        }

        // if no taker has been specified (open offer - i.e. typical marketplace listing)
        if(offer.taker==address(0)){

            // then there can't be taker token ids in the offer
            require(offer.takerIds.length==0, "taker ids with no taker");
        }

        // if a taker has been specified (peer-to-peer offer - i.e. direct trade between two users)
        else{

            if(checkIds){
                // then the taker must own all the taker token ids   
                for(uint i=0; i<offer.takerIds.length; i++){
                    require(ownerOf(offer.takerIds[i])==offer.taker, "bad taker ids");
                }
            }
        }

        // now return the hash
        return keccak256(abi.encode(
            offer.maker,
            offer.taker,
            keccak256(abi.encodePacked(offer.makerIds)),            
            keccak256(abi.encodePacked(offer.takerIds)),
            offer.takerWei,
            offer.expiry,
            offer.nonce,
            address(this)        // including the contract address prevents cross-contract replays  
        ));
    }

    // an offer is valid if:
    //  it's maker / taker details are valid 
    //  it has been signed by the maker
    //  it has not been cancelled or completed yet
    //  the parties own their tokens (if checking ids)
    //  the witness has signed it (if witnessing is enabled)
    //  the trade is valid (if requested)
    function validOffer(Offer memory offer, bytes memory signature, bytes memory witnessSignature, bool checkIds, bool checkTradeValid, uint checkValue) external view returns (bool){

        // will revert if the offer or signer is not valid or checks fail
        bytes32 _offer_hash = _getValidOfferHash(offer, signature, checkIds, checkTradeValid, checkValue);

        // check the witness if needed
        _validWitness(_offer_hash, witnessSignature);

        return true;
    }

    // if a market witness is set then they need to sign the offer hash too
    function _validWitness(bytes32 _offer_hash, bytes memory witnessSignature) internal view {
        if(_marketWitness!=address(0)){       
            require(_marketWitness == signerOfHash(_offer_hash, witnessSignature), "wrong witness");  
        }
    }

    // gets the hash of an offer and checks that it has been signed by the maker
    function _getValidOfferHash(Offer memory offer, bytes memory signature, bool checkIds, bool checkTradeValid, uint checkValue) internal view returns (bytes32){

        // get the offer signer 
        bytes32 _offer_hash = hashOffer(offer, checkIds);
        address _signer = signerOfHash(_offer_hash, signature);
        
        // the signer must be the maker
        require(offer.maker==_signer, "maker not signer");
        
        // the offer can't be cancelled or completed already
        require(_cancelledOrCompletedOffers[_offer_hash]!=true, "offer cancelled or completed");

        // if checking the trade then we need to check the taker side too
        if(checkTradeValid){

            address caller = _msgSender();

            // no trading when paused
            require(!marketPaused, "marketplace paused");

            // caller can't be the maker
            require(caller!=offer.maker, "caller is the maker");

            // if there is a taker specified then they must be the caller
            require(caller==offer.taker || offer.taker==address(0), "caller not the taker");

            // check the correct wei has been provided by the taker (can be 0)
            require(checkValue==offer.takerWei, "wrong payment sent");
        }

        return _offer_hash;
    }
      
    
    // (gas: these functions can run out of gas if too many id's are provided
    //       not limiting them here because block gas limits change over time and we don't know what they will be in future)

    // stops the offer hash from being usable in future
    // can only be cancelled by the maker or the contract owner    
    function cancelOffer(Offer memory offer) external {
        address caller = _msgSender();
        require(caller == offer.maker || caller == owner(), "caller not maker or contract owner");

        // get the offer hash 
        bytes32 _offer_hash = hashOffer(offer, false);
                
        // set the offer hash as cancelled
        _cancelledOrCompletedOffers[_offer_hash]=true;
    
        emit OfferCancelled(_offer_hash);       
    }

    // fills an offer
    
    // offers can't be traded when the market is paused or the contract is paused
    // offers must be valid and signed by the maker 
    // the caller has to be the taker or can be an unknown party if no taker is set
    // eth may or may not be required by the offer
    // tokens must belong to the makers and takers

    function acceptOffer(Offer memory offer, bytes memory signature, bytes memory witnessSignature) external payable reentrancyGuard {
        
        // CHECKS
        
        // will revert if the offer or signer is not valid 
        // will also check token ids to make sure they belong to the parties
        // will check the caller and eth matches the offer taker details 
        bytes32 _offer_hash = _getValidOfferHash(offer, signature, true, true, msg.value);
       
        // check the witness if needed
        _validWitness(_offer_hash, witnessSignature);
       
        // EFFECTS

        address caller = _msgSender();

        // transfer the maker tokens to the caller
        for(uint i=0; i<offer.makerIds.length; i++){
             _safeTransfer(offer.maker, caller, offer.makerIds[i], "");
        }

        // transfer the taker tokens to the maker 
        for(uint i=0; i<offer.takerIds.length; i++){
             _safeTransfer(caller, offer.maker, offer.takerIds[i], "");
        }

        // set the offer has as completed (stops the offer from being reused)
        _cancelledOrCompletedOffers[_offer_hash]=true;

        // INTERACTIONS

        // transfer the payment if one is present
        uint _fee = 0;
        if(msg.value>0){

            // calculate the marketplace fee (stored as basis points)
            // eg. 250 basis points is 2.5%  (250/10000) 
            _fee = msg.value * marketFee / 10000;
            uint _earned = msg.value - _fee;

            // safety check (should never be hit)
            assert(_fee>=0 && _earned>=0 && _earned<= msg.value && _fee+_earned==msg.value);
            
            // send the payment to the maker
            //   security note: calls to a maker should only revert if insufficient gas is sent by the caller/taker
            //   makers can't be smart contracts because makers need to sign the offer hash for us
            //    - currently only EOA's (externally owned accounts) can sign a message on the ethereum network
            //    - smart contracts don't have a private key and can't sign a message, so they can't be makers here
            //    - offers for specific makers can be blacklisted in the marketplace if required

            (bool success, ) = offer.maker.call{value:_earned}("");    
            require(success, "payment to maker failed");            
        }

        emit OfferAccepted(_offer_hash, offer.maker, caller, offer.makerIds, offer.takerIds, offer.takerWei, _fee);
    }  
    

    /// ERC2981 support

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == 0x2a55205a  // ERC2981
               || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyReciever, (salePrice * _royaltyFee) / 10000);
    }

    // the royalties fee is set in basis points (eg. 250 basis points = 2.5%)
    function setRoyalties(address newReceiver, uint16 basisPoints) external onlyOwner {
        require(basisPoints <= 10000);
        _royaltyReciever = newReceiver;
        _royaltyFee = basisPoints;
    }
}

// used to whitelist proxy accounts of OpenSea users so that they are automatically able to trade any item on OpenSea
contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}