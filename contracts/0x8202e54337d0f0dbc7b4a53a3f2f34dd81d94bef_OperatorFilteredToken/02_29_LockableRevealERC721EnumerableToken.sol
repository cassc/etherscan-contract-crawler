// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IToken.sol";
import "../interfaces/IRegistryConsumer.sol";
import "../interfaces/IRandomNumberProvider.sol";
import "../interfaces/IRandomNumberRequester.sol";
import "../extras/recovery/BlackHolePrevention.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../../@galaxis/registries/contracts/CommunityList.sol";
import "../../@galaxis/registries/contracts/CommunityRegistry.sol";
import "../overrides/ERC721Enumerable.sol";

import "hardhat/console.sol";

contract LockableRevealERC721EnumerableToken is IToken, ERC721Enumerable, Ownable, BlackHolePrevention {
    using Strings  for uint256; 
 
    bytes32 public constant TOKEN_CONTRACT_GIVEAWAY         = keccak256("TOKEN_CONTRACT_GIVEAWAY");
    bytes32 public constant TOKEN_CONTRACT_ACCESS_SALE      = keccak256("TOKEN_CONTRACT_ACCESS_SALE");
    bytes32 public constant TOKEN_CONTRACT_ACCESS_ADMIN     = keccak256("TOKEN_CONTRACT_ACCESS_ADMIN");
    bytes32 public constant TOKEN_CONTRACT_ACCESS_LOCK      = keccak256("TOKEN_CONTRACT_ACCESS_LOCK");
    bytes32 public constant TOKEN_CONTRACT_ACCESS_REVEAL    = keccak256("TOKEN_CONTRACT_ACCESS_REVEAL");

    function version() public view virtual returns (uint256) {
        return 2023071101;
    }


    IRegistryConsumer               public TheRegistry;
    string              constant    public REGISTRY_KEY_RANDOM_CONTRACT = "RANDOMV2_SSP";

    uint256                         public projectID;
    uint256                         public maxSupply;
    uint256                         public mintedSupply;    // minted incrementally
    uint256                         public mintedReserve;   
    uint256                         public reservedSupply;  // includes giveaway supply
    uint256                         public giveawaySupply;

    string                          public tokenPreRevealURI;
    string                          public tokenRevealURI;
    bool                            public transferLocked;
    bool                            public lastRevealRequested;

    mapping(uint16 => revealStruct) public reveals;
    mapping(uint256 => uint16)      public requestToRevealId;
    string                          public revealURI;
    uint16                          public currentRevealCount;
    string                          public contractURI;
    bool                            _initialized;
    bool                            public VRFShifting;
    
    CommunityRegistry               public myCommunityRegistry;

    using EnumerableSet for EnumerableSet.AddressSet;
    // onlyOwner can change contractControllers and transfer it's ownership
    // any contractController can setData
    EnumerableSet.AddressSet contractControllers;
    event contractControllerEvent(address _address, bool mode);
    EnumerableSet.AddressSet contractManagers;
    event contractManagerEvent(address _address, bool mode);

    event Locked(bool);
    event RandomProcessed(uint256 stage, uint256 randNumber, uint256 _shiftsBy, uint256 _start, uint256 _end);
    event ContractURIset(string contractURI);

    function setup(TokenConstructorConfig memory config) public virtual onlyOwner {
        require(!_initialized, "Token: Contract already initialized");
       
        ERC721.setup(config.erc721name, config.erc721symbol);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        if(chainId == 1 || chainId == 5 || chainId == 1337 || chainId == 31337 || chainId == 137 || chainId == 80001) {
            TheRegistry = IRegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
        } else {
            require(false, "Token: invalid chainId");
        }

        projectID           = config.projectID;
        tokenPreRevealURI   = config.tokenPreRevealURI;
        tokenRevealURI      = config.tokenRevealURI;
        maxSupply           = config.maxSupply;
        transferLocked      = config.transferLocked;
        reservedSupply      = config.reservedSupply;
        giveawaySupply      = config.giveawaySupply;

        CommunityList COMMUNITY_LIST = CommunityList(TheRegistry.getRegistryAddress("COMMUNITY_LIST"));
        (,address crAddr,) = COMMUNITY_LIST.communities(uint32(projectID));
        myCommunityRegistry = CommunityRegistry(crAddr);

        VRFShifting = config.VRFShifting;

        _initialized = true;
    }


    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override {
        if(from != address(0)) {
            require(!transferLocked, "Token: Transfers are not enabled");
        }
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    /**
     * @dev Sale: mint cards.
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_SALE
     */
    function mintIncrementalCards(uint256 numberOfCards, address recipient) external onlyAllowed(TOKEN_CONTRACT_ACCESS_SALE) {
        require(!lastRevealRequested, "Token: Cannot mint after last reveal");
        require(mintedSupply + numberOfCards <= maxSupply - reservedSupply, "Token: This would exceed the number of cards available");
        uint256 mintId = mintedSupply + 1;
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient, mintId++);
        }
        mintedSupply+=numberOfCards;
    }

    /**
     * @dev Admin: mint reserved cards.
     *   Should only mint reserved AFTER the sale is over.
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_ADMIN
     */
    function mintReservedCards(uint256 numberOfCards, address recipient) external onlyAllowed(TOKEN_CONTRACT_ACCESS_ADMIN) {
        require(lastRevealRequested, "Token: Last reveal must be requested first");
        require(mintedReserve + numberOfCards <= reservedSupply - giveawaySupply, "Token: This would exceed the number of reserved cards available");
        uint256 mintId = mintedSupply + mintedReserve + 1;
        for (uint j = 0; j < numberOfCards; j++) {
            _mint(recipient, mintId++);
        }
        mintedReserve+=numberOfCards;
    }

    /**
     * @dev DropRegistry util
     */
    function getFirstGiveawayCardId() public view returns (uint256) {
        return mintedSupply + reservedSupply - giveawaySupply + 1;
    }

    /**
     * @dev DropRegistry: mint specific giveaway card.
     *   Can only mint after reserve has been minted.
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_GIVEAWAY
     */
    function mintGiveawayCard(uint256 _index, address _recipient) external onlyAllowed(TOKEN_CONTRACT_GIVEAWAY) {
        require(lastRevealRequested, "Token: Last reveal must be requested first");
        require(mintedReserve == reservedSupply - giveawaySupply, "Token: Must mint reserved cards first");
        uint256 firstIndex = getFirstGiveawayCardId();
        require( _index >= firstIndex && _index < firstIndex + giveawaySupply, "Token: Card id not in range");
        _mint(_recipient, _index);
    }

    /**
     * @dev Admin: set PreRevealURI
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_ADMIN
     */
    function setPreRevealURI(string calldata _tokenPreRevealURI) external onlyAllowed(TOKEN_CONTRACT_ACCESS_ADMIN) {
        tokenPreRevealURI = _tokenPreRevealURI;
    }

    /**
     * @dev Admin: set RevealURI
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_ADMIN
     */
    function setRevealURI(string calldata _tokenRevealURI) external onlyAllowed(TOKEN_CONTRACT_ACCESS_ADMIN) {
        tokenRevealURI = _tokenRevealURI;
    }

    /**
     * @dev Admin: reveal tokens starting at prev range end to current supply
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_REVEAL
     */
    function revealAtCurrentSupply() external onlyAllowed(TOKEN_CONTRACT_ACCESS_REVEAL) {
        require(VRFShifting, "Token: VRF Shifting must be enabled");
        require(!lastRevealRequested, "Token: Last reveal already requested");
        require(reveals[currentRevealCount].RANGE_END < mintedSupply, "Token: Reveal request already exists");

        // make sure we have minted at least 1 token, else process() will fail with modulo / div by 0

        revealStruct storage currentReveal = reveals[++currentRevealCount];

        // if previous RANGE_END does not exist, this is 0
        currentReveal.RANGE_START = reveals[currentRevealCount-1].RANGE_END;
        currentReveal.RANGE_END = mintedSupply;

        require(currentReveal.RANGE_END - currentReveal.RANGE_START > 0, "Token: requires minted tokens for current range to be at least 1");

        //
        require(mintedSupply + reservedSupply < maxSupply, "Token: Please request LastReveal");

        currentReveal.REQUEST_ID = IRandomNumberProvider(TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
        requestToRevealId[currentReveal.REQUEST_ID] = currentRevealCount;
    }

    /**
     * @dev Admin: reveal tokens starting at prev range end to:
     *      - if(!VRFShifting) then RANGE_END = maxSupply
     *      - if(VRFShifting) then RANGE_END = maxSupply
     *
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_REVEAL
     */
    function lastReveal() external onlyAllowed(TOKEN_CONTRACT_ACCESS_REVEAL) {
        require(!lastRevealRequested, "Token: Last reveal already requested");
        require(reveals[currentRevealCount].RANGE_END < maxSupply, "Token: Reveal request already exists");
        lastRevealRequested = true;
        revealStruct storage currentReveal = reveals[++currentRevealCount];

        // if previous RANGE_END does not exist, this is 0
        currentReveal.RANGE_START = reveals[currentRevealCount-1].RANGE_END;

        // Normal VRF Shifting process
        if(VRFShifting) {
            // since reservedSupply 

            currentReveal.RANGE_END = mintedSupply + reservedSupply;
            // currentReveal.RANGE_END = maxSupply;

            require(currentReveal.RANGE_END - currentReveal.RANGE_START > 0, "Token: requires minted tokens for current range to be at least 1");

            currentReveal.REQUEST_ID = IRandomNumberProvider(TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT)).requestRandomNumberWithCallback();
            requestToRevealId[currentReveal.REQUEST_ID] = currentRevealCount;
        } else {
            // Non shifted token
            // Does not do a VRF call
            // Just sets max supply as revealed and emits RandomProcessed so Metadata Server ca pick it up and reveal things

            currentReveal.RANDOM_NUM = 0;
            currentReveal.SHIFT = 0;
            currentReveal.RANGE_START = 0;
            currentReveal.RANGE_END = maxSupply;

            emit RandomProcessed(
                currentRevealCount,
                currentReveal.RANDOM_NUM,
                currentReveal.SHIFT,
                currentReveal.RANGE_START,
                currentReveal.RANGE_END
            );
        }

    }

    /**
     * @dev Chainlink VRF callback
     */
    function process(uint256 _random, uint256 _requestId) external {
        require(VRFShifting, "Token: VRF Shifting must be enabled");
        require(msg.sender == TheRegistry.getRegistryAddress(REGISTRY_KEY_RANDOM_CONTRACT), "Token: process() Unauthorised caller");

        // get reveal using _requestId
        uint16 thisRevealId = requestToRevealId[_requestId];
        revealStruct storage thisReveal = reveals[thisRevealId];

        require(!thisReveal.processed, "Token: reveal already processed.");

        if(thisReveal.REQUEST_ID == _requestId) {
            thisReveal.RANDOM_NUM = _random / 2; // Set msb to zero

            // in the very rare case where RANDOM_NUM is 0, use currentReveal.RANGE_END / 3
            if(thisReveal.RANDOM_NUM == 0) {
                thisReveal.RANDOM_NUM = thisReveal.RANGE_END * (10 ** 5) / 3;
            }

            thisReveal.SHIFT = thisReveal.RANDOM_NUM % ( thisReveal.RANGE_END - thisReveal.RANGE_START );
            
            // in the very rare case where the shifting result is 0, do it again but divide by 3
            if(thisReveal.SHIFT == 0) {
                thisReveal.RANDOM_NUM = thisReveal.RANDOM_NUM / 3;
                thisReveal.SHIFT = thisReveal.RANDOM_NUM % ( thisReveal.RANGE_END - thisReveal.RANGE_START );
            }

            thisReveal.processed = true;

            emit RandomProcessed(
                thisRevealId,
                thisReveal.RANDOM_NUM,
                thisReveal.SHIFT,
                thisReveal.RANGE_START,
                thisReveal.RANGE_END
            );

        } else revert("Token: Incorrect requestId received");
    }


    function findRevealRangeForN(uint256 n) public view returns (uint16) {
        for(uint16 i = 1; i <= currentRevealCount; i++) {
            if(n <= reveals[i].RANGE_END) {
                return i;
            }
        }
        return 0;
    }

    function uri(uint256 n) public view returns (uint256) {
        uint16 rangeId = findRevealRangeForN(n); 
        // outside ranges
        if(rangeId == 0) {
            return n;
        }

        revealStruct memory currentReveal = reveals[rangeId];
        uint256 shiftedN = n + currentReveal.SHIFT;
        if (shiftedN <= currentReveal.RANGE_END) {
            return shiftedN;
        }
        return currentReveal.RANGE_START + shiftedN - currentReveal.RANGE_END;
    }

    /**
    * @dev Reserved are always at the end of current minted 
    */
    function _reserved(uint256 _tokenId) public view returns (bool) {
        if(_tokenId > mintedSupply + mintedReserve && _tokenId <= mintedSupply + reservedSupply) {
            return true;
        }
        return false;
    }

    /**
    * @dev Get metadata server url for tokenId
    */
    function tokenURI(uint256 _tokenId) public view override(IToken, ERC721) returns (string memory) {
        require(_exists(_tokenId) || _reserved(_tokenId), 'Token: Token does not exist');

        uint16 rangeId = findRevealRangeForN(_tokenId);
        // outside ranges
        if(rangeId == 0) {
            return tokenPreRevealURI;
        }

        revealStruct memory currentReveal = reveals[rangeId];

        // if random number was not set, return pre reveal
        // TODO: most likely remove this.. as we never get here.. we're already outside range
        if(currentReveal.RANDOM_NUM == 0) {
            return tokenPreRevealURI;
        }

        uint256 newTokenId = uri(_tokenId);        
        string memory folder = (newTokenId % 100).toString(); 
        string memory file = newTokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(tokenRevealURI, folder, slash, file));
    }

    /**
     * @dev Admin: Lock / Unlock transfers
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_LOCK
     */
    function setTransferLock(bool _locked) external onlyAllowed(TOKEN_CONTRACT_ACCESS_LOCK) {
        transferLocked = _locked;
        emit Locked(_locked);
    }


    function hasRole(bytes32 key, address user) public view returns (bool) {
        return myCommunityRegistry.hasRole(key, user);
    }

    /**
     * @dev Admin: Allow / Dissalow addresses
     */

    modifier onlyAllowed(bytes32 role) { 
        require(isAllowed(role, msg.sender), "Token: Unauthorised");
        _;
    }

    function isAllowed(bytes32 role, address user) public view returns (bool) { 
        return( user == owner() || hasRole(role, user));
    }

    function tellEverything() external view returns (TokenInfo memory) {
        
        revealStruct[] memory _reveals = new revealStruct[](currentRevealCount);
        for(uint16 i = 1; i <= currentRevealCount; i++) {
            _reveals[i - 1] = reveals[i];
        }

        uint256 contractManagers_length = contractManagers.length();
        address[] memory _managers = new address[](contractManagers_length);
        for(uint16 i = 0; i < contractManagers_length; i++) {
            _managers[i] = contractManagers.at(i);
        }

        uint256 contractControllers_length = contractControllers.length();
        address[] memory _controllers = new address[](contractControllers_length);
        for(uint16 i = 0; i < contractControllers_length; i++) {
            _controllers[i] = contractControllers.at(i);
        }

        return TokenInfo(
            name(),
            symbol(),
            projectID,
            maxSupply,
            mintedSupply,
            mintedReserve,
            reservedSupply,
            giveawaySupply,
            tokenPreRevealURI,
            tokenRevealURI,
            transferLocked,
            lastRevealRequested,
            totalSupply(),
            _reveals,
            owner(),
            _managers,
            _controllers,
            version(),
            VRFShifting
        );
    }

    function getTokenInfoForSale() external view returns (TokenInfoForSale memory) {
        return TokenInfoForSale(
            projectID,
            maxSupply,
            reservedSupply
        );
    }

    /**
     * @dev Admin: set setContractURI
     * - DEFAULT_ADMIN_ROLE or TOKEN_CONTRACT_ACCESS_ADMIN
     */
    function setContractURI(string memory _contractURI) external onlyAllowed(TOKEN_CONTRACT_ACCESS_ADMIN) {
        contractURI = _contractURI;
        emit ContractURIset(_contractURI);
    }
}