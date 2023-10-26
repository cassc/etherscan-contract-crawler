// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;                                                                                                                                                                                                                                            
                                                                                
//                ,|||||<              ~|||||'         `_+7ykKD%RDqmI*~`          
//                8@@@@@@8'           `Q@@@@@`     `^oB@@@@@@@@@@@@@@@@@R|`       
//               !@@@@@@@@Q;          L@@@@@J    '}Q@@@@@@QqonzJfk8@@@@@@@Q,      
//               Q@@@@@@@@@@j        `Q@@@@Q`  `m@@@@@@h^`         `?Q@@@@@*      
//              =@@@@@@@@@@@@D.      7@@@@@i  ~Q@@@@@w'              ^@@@@@*      
//              Q@@@@@m@@@@@@@Q!    `@@@@@Q  ;@@@@@@;                .txxxx:      
//             |@@@@@u *@@@@@@@@z   u@@@@@* `Q@@@@@^                              
//            `Q@@@@Q`  'W@@@@@@@R.'@@@@@B  7@@@@@%        :DDDDDDDDDDDDDD5       
//            c@@@@@7    `Z@@@@@@@QK@@@@@+  6@@@@@K        aQQQQQQQ@@@@@@@*       
//           `@@@@@Q`      ^Q@@@@@@@@@@@W   j@@@@@@;             ,6@@@@@@#        
//           t@@@@@L        ,8@@@@@@@@@@!   'Q@@@@@@u,        .=A@@@@@@@@^        
//          .@@@@@Q           }@@@@@@@@D     'd@@@@@@@@gUwwU%Q@@@@@@@@@@g         
//          j@@@@@<            +@@@@@@@;       ;wQ@@@@@@@@@@@@@@@Wf;8@@@;         
//          ~;;;;;              .;;;;;~           '!Lx5mEEmyt|!'    ;;;~          
//
// Powered By:    @niftygateway
// Author:        @niftynathang
// Collaborators: @conviction_1 
//                @stormihoebe
//                @smatthewenglish
//                @dccockfoster
//                @blainemalone
                                                                                
                                                                                                   

import "./ERC721Omnibus.sol";
import "../interfaces/IERC2309.sol";
import "../interfaces/IERC721MetadataGenerator.sol";
import "../interfaces/IERC721DefaultOwnerCloneable.sol";
import "../structs/NiftyType.sol";
import "../utils/Ownable.sol";
import "../utils/Signable.sol";
import "../utils/Withdrawable.sol";
import "../utils/Royalties.sol";

contract NiftyERC721Token is ERC721Omnibus, Royalties, Signable, Withdrawable, Ownable, IERC2309 {    
    using Address for address;        
    
    event NiftyTypeCreated(address indexed contractAddress, uint256 niftyType, uint256 idFirst, uint256 idLast);
    
    uint256 constant internal MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;    

    // A pointer to a contract that can generate token URI/metadata
    IERC721MetadataGenerator internal metadataGenerator;

    // Used to determine next nifty type/token ids to create on a mint call
    NiftyType internal lastNiftyType;

    // Sorted array of NiftyType definitions - ordered to allow binary searching
    NiftyType[] internal niftyTypes;               

    // Mapping from Nifty type to IPFS hash of canonical artifact file.
    mapping(uint256 => string) private niftyTypeIPFSHashes;

    constructor() {
        
    }                                     

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Omnibus, Royalties, NiftyPermissions) returns (bool) {
        return          
        interfaceId == type(IERC2309).interfaceId ||
        super.supportsInterface(interfaceId);
    }                                     

    function setMetadataGenerator(address metadataGenerator_) external {  
        _requireOnlyValidSender();
        if(metadataGenerator_ == address(0)) {
            metadataGenerator = IERC721MetadataGenerator(metadataGenerator_);
        } else {
            require(IERC165(metadataGenerator_).supportsInterface(type(IERC721MetadataGenerator).interfaceId), "Invalid Metadata Generator");        
            metadataGenerator = IERC721MetadataGenerator(metadataGenerator_);
        }        
    }

    function finalizeContract() external {
        _requireOnlyValidSender();
        require(!collectionStatus.isContractFinalized, ERROR_CONTRACT_IS_FINALIZED);        
        collectionStatus.isContractFinalized = true;
    }

    function tokenURI(uint256 tokenId) public virtual view override returns (string memory) {
        if(address(metadataGenerator) == address(0)) {
            return super.tokenURI(tokenId);
        } else {
            require(_exists(tokenId), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);        
            return metadataGenerator.tokenMetadata(tokenId, _getNiftyType(tokenId), bytes(""));
        }                
    }

    function contractURI() public virtual view override returns (string memory) {
        if(address(metadataGenerator) == address(0)) {
            return super.contractURI();
        } else {       
            return metadataGenerator.contractMetadata();
        }                
    }

    function tokenIPFSHash(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), ERROR_QUERY_FOR_NONEXISTENT_TOKEN);        
        return niftyTypeIPFSHashes[_getNiftyType(tokenId)];
    }    

    function setIPFSHash(uint256 niftyType, string memory ipfsHash) external {
        _requireOnlyValidSender();
        require(bytes(niftyTypeIPFSHashes[niftyType]).length == 0, "ERC721Metadata: IPFS hash already set");
        niftyTypeIPFSHashes[niftyType] = ipfsHash;        
    }

    function mint(uint256[] calldata amounts, string[] calldata ipfsHashes) external {
        _requireOnlyValidSender();
        
        require(amounts.length > 0 && ipfsHashes.length > 0, ERROR_INPUT_ARRAY_EMPTY);
        require(amounts.length == ipfsHashes.length, ERROR_INPUT_ARRAY_SIZE_MISMATCH);

        address to = collectionStatus.defaultOwner;                
        require(to != address(0), ERROR_TRANSFER_TO_ZERO_ADDRESS);                
        require(!collectionStatus.isContractFinalized, ERROR_CONTRACT_IS_FINALIZED);                
        
        uint88 initialIdLast = lastNiftyType.idLast;
        uint72 nextNiftyType = lastNiftyType.niftyType;
        uint88 nextIdCounter = initialIdLast + 1;
        uint88 firstNewTokenId = nextIdCounter;
        uint88 lastIdCounter = 0;

        for(uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, ERROR_NO_TOKENS_MINTED);            
            uint88 amount = uint88(amounts[i]);                        
            lastIdCounter = nextIdCounter + amount - 1;
            nextNiftyType++;
            
            if(bytes(ipfsHashes[i]).length > 0) {
                niftyTypeIPFSHashes[nextNiftyType] = ipfsHashes[i];
            }
            
            niftyTypes.push(NiftyType({
                isMinted: true,
                niftyType: nextNiftyType, 
                idFirst: nextIdCounter, 
                idLast: lastIdCounter
            }));

            emit NiftyTypeCreated(address(this), nextNiftyType, nextIdCounter, lastIdCounter);

            nextIdCounter += amount;            
        }
        
        uint256 newlyMinted = lastIdCounter - initialIdLast;        
                
        balances[to] += newlyMinted;

        lastNiftyType.niftyType = nextNiftyType;
        lastNiftyType.idLast = lastIdCounter;

        collectionStatus.amountCreated += uint88(newlyMinted);        

        emit ConsecutiveTransfer(firstNewTokenId, lastIdCounter, address(0), to);
    }        

    function setBaseURI(string calldata uri) external {
        _requireOnlyValidSender();
        _setBaseURI(uri);        
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }    

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function burnBatch(uint256[] calldata tokenIds) public {
        require(tokenIds.length > 0, ERROR_INPUT_ARRAY_EMPTY);
        for(uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }        
    }

    function getNiftyTypes() public view returns (NiftyType[] memory) {
        return niftyTypes;
    }

    function getNiftyTypeDetails(uint256 niftyType) public view returns (NiftyType memory) {
        uint256 niftyTypeIndex = MAX_INT;
        unchecked {
            niftyTypeIndex = niftyType - 1;
        }
        
        if(niftyTypeIndex >= niftyTypes.length) {
            revert('Nifty Type Does Not Exist');
        }
        return niftyTypes[niftyTypeIndex];
    }    
    
    function _isValidTokenId(uint256 tokenId) internal virtual view override returns (bool) {        
        return tokenId > 0 && tokenId <= collectionStatus.amountCreated;
    }    

    // Performs a binary search of the nifty types array to find which nifty type a token id is associated with
    // This is more efficient than iterating the entire nifty type array until the proper entry is found.
    // This is O(log n) instead of O(n)
    function _getNiftyType(uint256 tokenId) internal virtual override view returns (uint256) {        
        uint256 min = 0;
        uint256 max = niftyTypes.length - 1;
        uint256 guess = (max - min) / 2;
        
        while(guess < niftyTypes.length) {
            NiftyType storage guessResult = niftyTypes[guess];
            if(tokenId >= guessResult.idFirst && tokenId <= guessResult.idLast) {
                return guessResult.niftyType;
            } else if(tokenId > guessResult.idLast) {
                min = guess + 1;
                guess = min + (max - min) / 2;
            } else if(tokenId < guessResult.idFirst) {
                max = guess - 1;
                guess = min + (max - min) / 2;
            }
        }

        return 0;
    }       
}