// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import "./OBYToken.sol";
import "./BlackSquareNFT.sol";
import "./OBYTransfer_V2.sol";
import "./IlluminaNFT_V3.sol";



contract OBYTransfer_V3 {
    using Strings for uint256;

    OBYToken obyToken;
    BlackSquareNFT blackSquare;
    OBYTransfer_V2 obyTransfer_v2;
    IlluminaNFT_V3 illuminaNFT_v3;
    
    uint256 constant OBY_PER_CYCLE = 300;
    uint256 constant TOKEN_PER_EDITION = 25;
    uint256 public maxMintable = 5;

    address owner;
    address blacksquareAddress;
    bool public bulkMintable = true;
    bool public claimable;

    mapping(uint256 => mapping(uint256 => bool)) private _claimedInCycle;
    mapping(address => bool) private _eligibles;

    event RewardWithdrawn(uint256 amount, address sender);

    constructor(address _blackSquareAddress, address _obyAddress, bool _claimable, address _obyTransferAddress, address _illuminaNFT_V2) {
        blackSquare = BlackSquareNFT(_blackSquareAddress);
        obyToken = OBYToken(_obyAddress);
        obyTransfer_v2 = OBYTransfer_V2(_obyTransferAddress);
        illuminaNFT_v3 = IlluminaNFT_V3(_illuminaNFT_V2);
        owner = msg.sender;
        claimable = _claimable;
        blacksquareAddress = _blackSquareAddress;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "OBYTransfer: caller is not eligible");
        _;
    }

    modifier onlyEligible() {
        require(owner == msg.sender || _eligibles[msg.sender ] == true, "OBYTransfer: caller is not eligible");
        _;
    }

    function setEligibles(address _eligible, bool _val) public onlyOwner {
        _eligibles[_eligible] = _val;
    }

    function setClaimable (bool _claimable) public onlyEligible {
        claimable = _claimable;
    }

    function setBulkMintAttributes (uint256 _maxMintable, bool _bulkMintable) public onlyEligible {
        maxMintable = _maxMintable;
        bulkMintable =_bulkMintable;
    }

    function getOwnerOf (uint256 _tokenId) public view returns (address) {
        IERC721 nft = IERC721(blacksquareAddress);
        address tokenOwner = nft.ownerOf(_tokenId);

        return tokenOwner;
    }

    function getEditionMapping(uint256 _tokenId) public pure returns (uint256) {
        uint256 multiplier = 10;
        uint256 multipliedEdition = (_tokenId * multiplier) / TOKEN_PER_EDITION;

        uint256 editionId = multipliedEdition % multiplier == 0 ? multipliedEdition / multiplier : (multipliedEdition / multiplier) + 1;

        return editionId;
    }

    function getBlackSquareEditionAttributes (uint256 tokenId) public view returns (uint256, uint256, uint256) {
        BlackSquareNFT.Edition[] memory editions = blackSquare.getEditions();
        uint256 editionId = getEditionMapping(tokenId);

        uint256 cycle = editions[editionId].cycle;
        uint256 illuminationTimeStamp = editions[editionId].illuminationTimeStamp;

        return (cycle, editionId, illuminationTimeStamp);
    }

    function getFirstEditionToBeIlluminated (uint256 _lastEditionToCheck) public view returns (uint256, uint256, uint256) {
        BlackSquareNFT.Edition[] memory editions = blackSquare.getEditions();
        uint256 firstEdition = blackSquare.getFirstEditionToSetIlluminationDate();

        uint256 ediontTo = editions[_lastEditionToCheck].id;
        uint256 illu = editions[_lastEditionToCheck].illuminationTimeStamp;

        BlackSquareNFT.Edition[] memory returnEditions = new BlackSquareNFT.Edition[](editions.length);

        if (firstEdition > 0) {
           
                uint256 l = editions.length;
                for(uint i = 0; i < l; i++) {
                    for(uint j = i + 1; j < l ; j++) {
                        if(editions[i].illuminationTimeStamp > editions[j].illuminationTimeStamp) {
                            BlackSquareNFT.Edition memory temp = editions[i];
                            returnEditions[i] = returnEditions[j];
                            returnEditions[j] = temp;
                        }
                    }
                }
            firstEdition = returnEditions[_lastEditionToCheck].id;
            
        }
        return (firstEdition, ediontTo, illu);
    }

    function transferOBYPerToken(uint256 _tokenId) external {
        uint256 transferableOby = 0;
        (uint256 cycle, , uint256 illuminationTimeStamp) = getBlackSquareEditionAttributes(_tokenId);

        if (cycle > 0 && getOwnerOf(_tokenId) == msg.sender && claimable) {

            for (uint256 i = 1; i <= cycle; i++) {
                if (cycle == 1 && !obyTransfer_v2.getAlreadyClaimed(_tokenId) && illuminationTimeStamp < block.timestamp) {
                    transferableOby += OBY_PER_CYCLE;
                    obyTransfer_v2.setClaimed(false, _tokenId);
                }

                if (cycle > 1 && !_claimedInCycle[_tokenId][i] && illuminationTimeStamp < block.timestamp) {
                    transferableOby += OBY_PER_CYCLE;
                    _claimedInCycle[_tokenId][i] = true;
                }
            }

            obyToken.mint(msg.sender, transferableOby);

        }
        emit RewardWithdrawn(transferableOby, msg.sender);
    }

    

    function transferOBYPerCycle() external {
        uint256[] memory tokens = blackSquare.getTokensHeldByUser(msg.sender);
        uint256 transferableOby = 0;

        if (claimable) {
            for (uint256 i = 0; i < tokens.length; i++) {
                (uint256 cycle, , uint256 illuminationTimeStamp) = getBlackSquareEditionAttributes(tokens[i]);

                if (cycle == 1 && !obyTransfer_v2.getAlreadyClaimed(tokens[i]) && illuminationTimeStamp < block.timestamp) {
                    transferableOby += OBY_PER_CYCLE;
                    obyTransfer_v2.setClaimed(true, tokens[i]);
                }

                if (cycle > 1 && !_claimedInCycle[tokens[i]][cycle] && illuminationTimeStamp < block.timestamp) {
                    transferableOby += OBY_PER_CYCLE;
                    _claimedInCycle[tokens[i]][cycle] = true;
                }
            }
        }

        if (transferableOby > 0) {
            obyToken.mint(msg.sender, transferableOby);
        }

        emit RewardWithdrawn(transferableOby, msg.sender);
    }


    function getAlreadyClaimedInCycle(uint256 _tokenId, uint256 _cycle) public view returns (bool) {
        return _claimedInCycle[_tokenId][_cycle];
    }


    function getTransferableOBYPerCycle() external view returns (uint256) {
        uint256[] memory tokens = blackSquare.getTokensHeldByUser(msg.sender);
        uint256 transferableOby = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256 cycle, , uint256 illuminationTimeStamp) = getBlackSquareEditionAttributes(tokens[i]);

           if (cycle == 1 && !obyTransfer_v2.getAlreadyClaimed(tokens[i]) && illuminationTimeStamp < block.timestamp) {
                    transferableOby += OBY_PER_CYCLE;
            }

            if (cycle > 1 && !_claimedInCycle[tokens[i]][cycle] && illuminationTimeStamp < block.timestamp) {
                transferableOby += OBY_PER_CYCLE;
            }
        }

        return transferableOby;
    }

    function getTransferableOBYPerToken(uint256 _tokenId, bool _checkBeforePurchase) external view returns (uint256) {
        uint256 transferableOby = 0;
        (uint256 cycle, , uint256 illuminationTimeStamp) = getBlackSquareEditionAttributes(_tokenId);

        if (cycle > 0 && claimable) {

            for (uint256 i = 1; i <= cycle; i++) {
                
                if (cycle == 1 && !obyTransfer_v2.getAlreadyClaimed(_tokenId)) {
                    if (_checkBeforePurchase) {
                        transferableOby += OBY_PER_CYCLE;
                    }
                    if (!_checkBeforePurchase && illuminationTimeStamp < block.timestamp) {
                        transferableOby += OBY_PER_CYCLE;
                    }
                }

                if (cycle > 1 && !_claimedInCycle[_tokenId][i]) {
                    if (_checkBeforePurchase) {
                        transferableOby += OBY_PER_CYCLE;
                    }
                    if (!_checkBeforePurchase && illuminationTimeStamp < block.timestamp) {
                        transferableOby += OBY_PER_CYCLE;
                    }
                }
            }
        }
        return transferableOby;
    }

    function mintIlluminaInBulk (string[] memory _ipfsHashes, uint256[] memory _tokens, uint256 _lastEditionToCheck) external {
        if (bulkMintable && _ipfsHashes.length == _tokens.length && _tokens.length == maxMintable) {
            (uint256 editionId,,) = getFirstEditionToBeIlluminated(_lastEditionToCheck);
            for (uint256 i = 0; i < _tokens.length; i++) {
                illuminaNFT_v3.externalFulfillRequirements(_tokens[i], msg.sender);
                illuminaNFT_v3.externalHandleMint(_ipfsHashes[i], editionId, msg.sender);
            }
        }
    }
}