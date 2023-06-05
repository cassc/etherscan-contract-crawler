pragma solidity 0.8.4;

import "./ERC721.sol";
import "../interface/ICloneablePaymentSplitter.sol";
import "../interface/IERC2981.sol";
import "../standard/ERC721Burnable.sol";
import "../util/Clones.sol";

/** 
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  .***   XXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  ,*********  XXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXX  ***************  XXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXX  .*******************  XXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXX  ***********    **********  XXXXXXXX
 * XXXXXXXXXXXXXXXXXXXX   ***********       ***********  XXXXXX
 * XXXXXXXXXXXXXXXXXX  ***********         ***************  XXX
 * XXXXXXXXXXXXXXXX  ***********           ****    ********* XX
 * XXXXXXXXXXXXXXXX *********      ***    ***      *********  X
 * XXXXXXXXXXXXXXXX  **********  *****          *********** XXX
 * XXXXXXXXXXXX   /////.*************         ***********  XXXX
 * XXXXXXXXX  /////////...***********      ************  XXXXXX
 * XXXXXXX/ ///////////..... /////////   ///////////   XXXXXXXX
 * XXXXXX  /    //////.........///////////////////   XXXXXXXXXX
 * XXXXXXXXXX .///////...........//////////////   XXXXXXXXXXXXX
 * XXXXXXXXX .///////.....//..////  /////////  XXXXXXXXXXXXXXXX
 * XXXXXXX# /////////////////////  XXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXX   ////////////////////   XXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XX   ////////////// //////   XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 * XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 *
 * @dev Nifty Gateway extension of customized NFT contract, encapsulates
 * logic for minting new tokens, and concluding the minting process. 
 */
contract NiftyBuilderInstance is ERC721, ERC721Burnable, IERC2981 {

    event RoyaltyReceiverUpdated(uint256 indexed niftyType, address previousReceiver, address newReceiver);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);

    // The artist associated with the collection.
    string private _creator;    

    uint256 immutable public _percentageTotal;
    mapping(uint256 => uint256) public _percentageRoyalty;

    mapping (uint256 => address) _royaltySplitters;
    mapping (uint256 => address) _royaltyReceivers;

    // Number of NFTs minted for a given 'typeCount'. 
    mapping (uint256 => uint256) public _mintCount;

    /**
     * @dev Serves as a gas cost optimized boolean flag 
     * to indicate whether the minting process has been 
     * concluded for a given 'typeCount', correspinds 
     * to the {_getFinalized} and {setFinalized}.
     */
    mapping (uint256 => bytes32) private _finalized;    

    /**
     * @dev Emitted when tokens are created.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);

    /**
     * @dev Ultimate instantiation of a Nifty Gateway NFT collection. 
     * 
     * @param name Of the collection being deployed.
     * @param symbol Shorthand token identifier, for wallets, etc.
     * @param id Number instance deployed by {BuilderShop} contract.
     * @param typeCount The number of different Nifty types (different 
     * individual NFTs) associated with the deployed collection.
     * @param baseURI The location where the artifact assets are stored.
     * @param creator_ The artist associated with the collection.
     * @param niftyRegistryContract Points to the repository of authenticated
     * addresses for stateful operations. 
     * @param defaultOwner Intial receiver of all newly minted NFTs.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 id,
        uint256 typeCount,
        string memory baseURI,
        string memory creator_,        
        address niftyRegistryContract,
        address defaultOwner) ERC721(name, symbol, id, baseURI, typeCount, defaultOwner, niftyRegistryContract) {
        
        _creator = creator_;
        _percentageTotal = 10000;        
    }

    function setRoyaltyBips(uint256 niftyType, uint256 percentageRoyalty_) external onlyValidSender {
        require(percentageRoyalty_ <= _percentageTotal, "NiftyBuilderInstance: Illegal argument more than 100%");
        _percentageRoyalty[niftyType] = percentageRoyalty_;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public override view returns (address, uint256) {        
        require(_exists(tokenId), "NiftyBuilderInstance: operator query for nonexistent token");
        uint256 niftyType = _getNiftyTypeId(tokenId);
        uint256 royaltyAmount = (salePrice * _percentageRoyalty[niftyType]) / _percentageTotal;
        address royaltyReceiver = _getRoyaltyReceiverByNiftyType(niftyType);
        require(royaltyReceiver != address(0), "NiftyBuilderInstance: No royalty receiver");
        return (royaltyReceiver, royaltyAmount);
    }

    // This function must be called after builder shop instance is created - it can be called again
    // to change the split; call this once per nifty type to set up royalty payments properly
    function initializeRoyalties(address splitterImplementation, uint256 niftyType, address[] calldata payees, uint256[] calldata shares_) external onlyValidSender {
        address previousReceiver = _getRoyaltyReceiverByNiftyType(niftyType);
        address newReceiver = address(0);
        if(payees.length == 1) {
            newReceiver = payees[0];
            _royaltyReceivers[niftyType] = newReceiver;
            delete _royaltySplitters[niftyType];
        } else {            
            delete _royaltyReceivers[niftyType];
            require(IERC165(splitterImplementation).supportsInterface(type(ICloneablePaymentSplitter).interfaceId), "Not a valid payment splitter");
            newReceiver = payable (Clones.clone(splitterImplementation));
            ICloneablePaymentSplitter(newReceiver).initialize(payees, shares_);
            _royaltySplitters[niftyType] = newReceiver;        
        }

        emit RoyaltyReceiverUpdated(niftyType, previousReceiver, newReceiver);        
    }

    function getRoyaltyReceiverByTokenId(uint256 tokenId) public view returns (address) {        
        return _getRoyaltyReceiverByNiftyType(_getNiftyTypeId(tokenId));
    }

    function getRoyaltyReceiverByNiftyType(uint256 niftyType) public view returns (address) {
        return _getRoyaltyReceiverByNiftyType(niftyType);
    }

    function releaseRoyalties(address payable account) external {
        uint256 totalPaymentAmount = 0;
        for(uint256 niftyType = 1; niftyType <= _typeCount; niftyType++) {
            address paymentSplitterAddress = _royaltySplitters[niftyType];
            if(paymentSplitterAddress != address(0)) {
                ICloneablePaymentSplitter paymentSplitter = ICloneablePaymentSplitter(paymentSplitterAddress);    
                uint256 pendingPaymentAmount = paymentSplitter.pendingPayment(account);
                if(pendingPaymentAmount > 0) {
                    totalPaymentAmount += pendingPaymentAmount;
                    paymentSplitter.release(account);
                }
            }            
        }

        if(totalPaymentAmount > 0) {
            emit PaymentReleased(account, totalPaymentAmount);
        }    
    }

    function releaseRoyalties(IERC20 token, address account) external {
        uint256 totalPaymentAmount = 0;
        for(uint256 niftyType = 1; niftyType <= _typeCount; niftyType++) {
            address paymentSplitterAddress = _royaltySplitters[niftyType];
            if(paymentSplitterAddress != address(0)) {
                ICloneablePaymentSplitter paymentSplitter = ICloneablePaymentSplitter(paymentSplitterAddress);    
                uint256 pendingPaymentAmount = paymentSplitter.pendingPayment(token, account);
                if(pendingPaymentAmount > 0) {
                    totalPaymentAmount += pendingPaymentAmount;
                    paymentSplitter.release(token, account);
                }
            }            
        }

        if(totalPaymentAmount > 0) {
            emit ERC20PaymentReleased(token, account, totalPaymentAmount);
        }    
    }
    
    function pendingRoyaltyPayment(address account) external view returns (uint256) {
        uint256 totalPaymentAmount = 0;
        for(uint256 niftyType = 1; niftyType <= _typeCount; niftyType++) {
            address paymentSplitterAddress = _royaltySplitters[niftyType];
            if(paymentSplitterAddress != address(0)) {
                ICloneablePaymentSplitter paymentSplitter = ICloneablePaymentSplitter(paymentSplitterAddress);    
                totalPaymentAmount += paymentSplitter.pendingPayment(account);
            }            
        }
        return totalPaymentAmount;
    }

    function pendingRoyaltyPayment(IERC20 token, address account) external view returns (uint256) {
        uint256 totalPaymentAmount = 0;
        for(uint256 niftyType = 1; niftyType <= _typeCount; niftyType++) {
            address paymentSplitterAddress = _royaltySplitters[niftyType];
            if(paymentSplitterAddress != address(0)) {
                ICloneablePaymentSplitter paymentSplitter = ICloneablePaymentSplitter(paymentSplitterAddress);    
                totalPaymentAmount += paymentSplitter.pendingPayment(token, account);
            }            
        }
        return totalPaymentAmount;
    }

    /**
     * @dev Generate canonical Nifty Gateway token representation. 
     * Nifty contracts have a data model called a 'niftyType' (typeCount) 
     * The 'niftyType' refers to a specific nifty in our contract, note 
     * that it gives no information about the edition size. In a given 
     * contract, 'niftyType' 1 could be an edition of 10, while 'niftyType' 
     * 2 is a 1/1, etc.
     * The token IDs are encoded as follows: {id}{niftyType}{edition #}
     * 'niftyType' has 4 digits, and edition number has 5 digits, to allow 
     * for 99999 possible 'niftyType' and 99999 of each edition in each contract.
     * Example token id: [5000100270]
     * This is from contract #5, it is 'niftyType' 1 in the contract, and it is 
     * edition #270 of 'niftyType' 1.
     * Example token id: [5000110000]
     * This is from contract #5, it is 'niftyType' 1 in the contract, and it is 
     * edition #10000 of 'niftyType' 1.
     */
    function _encodeTokenId(uint256 niftyType, uint256 tokenNumber) private view returns (uint256) {
        return (topLevelMultiplier + (niftyType * midLevelMultiplier) + tokenNumber);
    }

    /**
     * @dev Determine whether it is possible to mint additional NFTs for this 'niftyType'.
     */
    function _getFinalized(uint256 niftyType) public view returns (bool) {
        bytes32 chunk = _finalized[niftyType / 256];
        return (chunk & bytes32(1 << (niftyType % 256))) != 0x0;
    }

    /**
     * @dev Prevent the minting of additional NFTs of this 'niftyType'.
     */
    function setFinalized(uint256 niftyType) public onlyValidSender {
        uint256 quotient = niftyType / 256;
        bytes32 chunk = _finalized[quotient];
        _finalized[quotient] = chunk | bytes32(1 << (niftyType % 256));
    }

    /**
     * @dev The artist of this collection.
     */
    function creator() public view virtual returns (string memory) {
        return _creator;
    }

    /**
     * @dev Assign the root location where the artifact assets are stored.
     */
    function setBaseURI(string memory baseURI) public onlyValidSender {
        _setBaseURI(baseURI);
    }

    /**
     * @dev Allow owner to change nifty name, by 'niftyType'.
     */
    function setNiftyName(uint256 niftyType, string memory niftyName) public onlyValidSender {
        _setNiftyTypeName(niftyType, niftyName);
    }

    /**
     * @dev Assign the IPFS hash of canonical artifcat file, by 'niftyType'.
     */   
    function setNiftyIPFSHash(uint256 niftyType, string memory hashIPFS) public onlyValidSender {
        _setTokenIPFSHashNiftyType(niftyType, hashIPFS);
    }

    /**
     * @dev Create specified number of nifties en masse.
     * Once an NFT collection is spawned by the factory contract, we make calls to set the IPFS
     * hash (above) for each Nifty type in the collection. 
     * Subsequently calls are issued to this function to mint the appropriate number of tokens 
     * for the project.
     */
    function mintNifty(uint256 niftyType, uint256 count) public onlyValidSender {
        require(!_getFinalized(niftyType), "NiftyBuilderInstance: minting concluded for nifty type");
            
        uint256 tokenNumber = _mintCount[niftyType] + 1;
        uint256 tokenId00 = _encodeTokenId(niftyType, tokenNumber);
        uint256 tokenId01 = tokenId00 + count - 1;
        
        for (uint256 tokenId = tokenId00; tokenId <= tokenId01; tokenId++) {
            _owners[tokenId] = _defaultOwner;
        }
        _mintCount[niftyType] += count;
        _balances[_defaultOwner] += count;

        emit ConsecutiveTransfer(tokenId00, tokenId01, address(0), _defaultOwner);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }    

    function _getRoyaltyReceiverByNiftyType(uint256 niftyType) private view returns (address) {
        if(_royaltyReceivers[niftyType] != address(0)) {            
            return _royaltyReceivers[niftyType];
        } else if(_royaltySplitters[niftyType] != address(0)) {            
            return _royaltySplitters[niftyType];
        }

        return address(0);   
    }
}