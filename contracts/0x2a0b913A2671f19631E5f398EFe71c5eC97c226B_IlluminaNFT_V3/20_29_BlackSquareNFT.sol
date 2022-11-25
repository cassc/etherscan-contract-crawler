// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import './ERC2981/ERC2981ContractWideRoyalties.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Erc721OperatorFilter/IOperatorFilter.sol";
import "./OBYToken.sol";


contract BlackSquareNFT is ERC721, Ownable, ERC2981ContractWideRoyalties {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 private rewardPerCycle;
    uint256 public totalCycleCount = 0;
    uint256 constant THRESHOLD = 25;
    uint256 constant TOKENS_PER_EDITION = 25;
    uint256 constant MAX_NUMBER_EDITIONS = 58;

    address private treasury;

    string public openSeaContractURI;
    string public baseURI;

    OBYToken obyToken;
    IOperatorFilter operatorFilter;
    Counters.Counter private _editionIds;
    Counters.Counter private _tokenIds;

   struct Edition {
        uint256[TOKENS_PER_EDITION] tokens;
        uint256 illuminationTimeStamp;
        uint256 lastUpdateTimestamp;
        uint256 cycle;
        uint256 id;
        string editionThumbnail;
        string illumination;
    }

    struct OwnerReward {
        uint256 rewardPaid;
        uint256 rewardStored;
    }

    struct CreateEditionStruct {
        uint256[TOKENS_PER_EDITION] tokens;
        uint256 illuminationMoment;
        string editionThumbnail;
        string illumination;
    }

    mapping(uint256 => mapping(uint256 => OwnerReward)) private _ownersReward;
    mapping(address => bool) private _eligibles;
    mapping(uint256 => Edition) private _editions;
    mapping(uint256 => uint256) private _editionOfToken;
    mapping(address => uint256) private _totalRewardsClaimed;

    event RewardWithdrawn(uint256 amount, address sender);
    event EditionCreated(uint256 editionId);


    constructor(address obyAddress, address _treasury, uint256 _royaltyValue, string memory _openSeaContractURI, string memory _blackSquareBaseURI,
    uint256 _rewardPerCycle, address _operatorFilter) ERC721("BlackSquare", "B2") {
        obyToken = OBYToken(obyAddress);
        operatorFilter = IOperatorFilter(_operatorFilter);
        treasury = _treasury;
        openSeaContractURI = _openSeaContractURI;
        baseURI = _blackSquareBaseURI;
        rewardPerCycle = _rewardPerCycle;
        _setRoyalties(_treasury, _royaltyValue);
    }

    modifier onlyEligible() {
        require(owner() == _msgSender() || _eligibles[_msgSender()] == true, "BlackSquareNFT: caller is not eligible");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        openSeaContractURI = _contractURI;
    }

    function setBaseURI(string memory _blackSquareBaseURI) external onlyOwner {
        baseURI = _blackSquareBaseURI;
    }


    function setRewardPerCycle(uint256 _rewardPerCycle) external onlyOwner {
        rewardPerCycle = _rewardPerCycle;
    }

    function setRoyalties(address recipient, uint256 value) external onlyOwner {
        _setRoyalties(recipient, value);
    }

    function setEligibles(address _eligible) external onlyOwner  {
        _eligibles[_eligible] = true;

        
    }

    function contractURI() public view returns (string memory) {
        return openSeaContractURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721) {
        if (
            from != address(0) &&
            to != address(0) &&
            !_mayTransfer(msg.sender, tokenId)
        ) {
            revert("ERC721OperatorFilter: illegal operator");
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _mayTransfer(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        IOperatorFilter filter = operatorFilter;
        if (address(filter) == address(0)) return true;
        if (operator == ownerOf(tokenId)) return true;
        return filter.mayTransfer(msg.sender);
    }

    function getEditions() public view returns (Edition[] memory) {
        Edition[] memory editions = new Edition[](_editionIds.current() + 1);

        for (uint256 editionCounter = 1; editionCounter <= _editionIds.current(); editionCounter++){
            editions[editionCounter] = _editions[editionCounter];
        }
        return editions;
    }

    function deleteEdition (uint256 editionId) public onlyOwner {
        delete _editions[editionId];
    }

    function createEdition(CreateEditionStruct memory _createEditionStruct) public onlyOwner  {
        _editionIds.increment();
        uint256 editionId = _editionIds.current();
        

        for (uint256 i = 0; i < _createEditionStruct.tokens.length; i++) {
            _editionOfToken[_createEditionStruct.tokens[i]] = _editionIds.current();
        }

        _editions[editionId].tokens = _createEditionStruct.tokens;
        _editions[editionId].illuminationTimeStamp = _createEditionStruct.illuminationMoment;
        _editions[editionId].lastUpdateTimestamp = block.timestamp;
        _editions[editionId].cycle = 1;
        _editions[editionId].id = editionId;
        _editions[editionId].editionThumbnail = _createEditionStruct.editionThumbnail;
        _editions[editionId].illumination = _createEditionStruct.illumination;

        emit EditionCreated(editionId);
    }


    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIds.current();
    }

    function getRewardInOBY () public view returns (uint256, uint256) {
        uint256[] memory tokens = getTokensHeldByUser(_msgSender());

        require(tokens.length > 0, 'NO BlackSquares held');
        uint256 availableReward = 0;

        uint256 paidReward = _totalRewardsClaimed[_msgSender()];

        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256 rewardPertoken, ,) = _getAvailableRewardInOby(tokens[i]);
            availableReward += rewardPertoken;
            
        }
        return (availableReward, paidReward);
    }

    function claimRewardInOBY () public returns (uint256) {
        uint256[] memory tokens = getTokensHeldByUser(_msgSender());

        require(tokens.length > 0, 'NO BlackSquares held');
        uint256 availableReward = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            (uint256 rewardPertoken, uint256 cycle, uint256 rewardStoredPrev) = _getAvailableRewardInOby(tokens[i]);
            availableReward += rewardPertoken;

            uint256 tokenId = tokens[i];

            uint256 previousCycle = cycle > 1 ? cycle - 1 : 1;
            uint256 rewardPaid = rewardPertoken - rewardStoredPrev;

            _ownersReward[tokenId][cycle].rewardPaid += rewardPaid;

            _totalRewardsClaimed[_msgSender()] += rewardPertoken;
            _ownersReward[tokenId][cycle].rewardStored = 0;
            if (cycle > 1) {
                _ownersReward[tokenId][previousCycle].rewardStored = 0;
            }
        }

        require(availableReward > 0, 'No OBY available to mint');

        if (availableReward > 0) {
            obyToken.mint(_msgSender(), availableReward);
        }

        emit RewardWithdrawn(availableReward, _msgSender());
        
        return availableReward;
    }

    function getTokensHeldByUser(address user) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(user);
        uint256[] memory emptyTokens = new uint256[](0);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 j = 0;

        for (uint256 i = 1; i <= _tokenIds.current(); i++ ) {
            address tokenOwner = ownerOf(i);

            if (tokenOwner == user) {
                tokenIds[j] = i;
                j++;
            }
        }
        if (tokenIds.length > 0) {
            return tokenIds;
        }  else {
            return emptyTokens;
        }
    }

    function mintAndDrop(address[] memory recipients, CreateEditionStruct[] memory _createEditionStruct) public onlyOwner {
        uint256 editionCount = 0;

        if(_editionIds.current() <= MAX_NUMBER_EDITIONS) {
            for (uint256 i = 0; i < recipients.length; i++) {
                _tokenIds.increment();
                uint256 currentTokenId = _tokenIds.current();

                unchecked {
                    _mint(recipients[i], currentTokenId);

                    if (currentTokenId == 25 || currentTokenId > 25 && currentTokenId % 25 ==  0) {
                        createEdition(_createEditionStruct[editionCount]);
                        editionCount++;
                    }
                }
            }
        }
    }

    function editEdition(uint256 _editionId, uint256 _illuminationTimeStamp) public onlyEligible returns (uint256) {
        updateStoredReward(_editionId);

        _editions[_editionId].illuminationTimeStamp = _illuminationTimeStamp;
        _editions[_editionId].lastUpdateTimestamp = block.timestamp;
        _editions[_editionId].cycle += 1;

        totalCycleCount ++;

        return _editionId;
    }

    function updateStoredReward(uint256 editionId) public onlyEligible  {
        uint256 editionCycle = _editions[editionId].cycle;
        for (uint256 tokenId = 0; tokenId < _editions[editionId].tokens.length; tokenId++ ) {
            uint256 currentToken = _editions[editionId].tokens[tokenId];

            // Normal update where cycle is > 1, Up to the normal rewardPerPeriod was paid out & There is a stored reward >= 0
            if (_ownersReward[currentToken][editionCycle].rewardPaid <= (rewardPerCycle / 10000) && editionCycle > 1 && _ownersReward[currentToken][editionCycle - 1].rewardStored >= 0) {
                _ownersReward[currentToken][editionCycle].rewardStored =  (rewardPerCycle / 10000) -  _ownersReward[currentToken][editionCycle].rewardPaid + _ownersReward[currentToken][editionCycle - 1].rewardStored;

            // We are in Cycle one, so there is no previously stored reward. Now everything gets stored which is a positive amount or 0
            } else if (_ownersReward[currentToken][editionCycle].rewardPaid <= (rewardPerCycle / 10000) && editionCycle == 1) {
                _ownersReward[currentToken][editionCycle].rewardStored = (rewardPerCycle / 10000) -  _ownersReward[currentToken][editionCycle].rewardPaid;

            // In case due to some rounding errors etc. RewardPaid > Reward, Only Stored Reward is carried over if Cycle > 1 and Stored Reward is bigger than 0
            } else if (_ownersReward[currentToken][editionCycle].rewardPaid > (rewardPerCycle / 10000) && editionCycle > 1 && _ownersReward[currentToken][editionCycle - 1].rewardStored > 0) {
                _ownersReward[currentToken][editionCycle].rewardStored = _ownersReward[currentToken][editionCycle - 1].rewardStored;

            // Handle the Edge Cases
            } else {
                _ownersReward[currentToken][editionCycle].rewardStored = 0;
            }
            
        }
        
    }

    function getFirstEditionToSetIlluminationDate() public view returns (uint256) {
        for (uint256 editionCounter = 1; editionCounter <= _editionIds.current(); editionCounter++){
            if (_editions[editionCounter].illuminationTimeStamp < block.timestamp) {
                return editionCounter;
            }
        }
        return 0;
    }

    function getAvailableIlluminaCount() public view returns (uint256) {
        uint256 availableIlluminas = totalCycleCount * THRESHOLD;
        for (uint256 editionCounter = 1; editionCounter <= _editionIds.current(); editionCounter++){
            if (_editions[editionCounter].illuminationTimeStamp < block.timestamp) {
                availableIlluminas += THRESHOLD;
            }
        }
        return availableIlluminas;
    }

    function setIlluminationTimeStamp(uint256 _editionId, uint256 _illuminationTimeStamp) public onlyOwner {
        _editions[_editionId].illuminationTimeStamp = _illuminationTimeStamp;
    }

     function _getAvailableRewardInOby(uint256 tokenId) internal view returns (uint256, uint256, uint256) {
        uint256 editionId = _editionOfToken[tokenId];

        require(editionId != 0, 'Token Not associated with any Edition');

        uint256 illuminationTimeStamp = _editions[editionId].illuminationTimeStamp;
        uint256 cycle = _editions[editionId].cycle;
        uint256 previousCycle = cycle > 1 ? cycle - 1 : 1;
        uint256 lastUpdateTimestamp = _editions[editionId].lastUpdateTimestamp;

        uint256 rewardPaid = _ownersReward[tokenId][cycle].rewardPaid > 0 ? _ownersReward[tokenId][cycle].rewardPaid : 0;
        uint256 rewardStoredPrev = cycle > 1 ? _ownersReward[tokenId][previousCycle].rewardStored : 0;

        // We are in the normal distribution Cycle
        if (lastUpdateTimestamp < illuminationTimeStamp && block.timestamp < illuminationTimeStamp && block.timestamp > lastUpdateTimestamp) {
            uint256 rewardPerSecond = rewardPerCycle / (illuminationTimeStamp - lastUpdateTimestamp);

            uint256 rewardPayableFromCycle = (((rewardPerSecond) * ((block.timestamp) - lastUpdateTimestamp)) / 10000) - rewardPaid;

            uint256 returnableAmount = rewardPayableFromCycle >= 1 ? rewardPayableFromCycle + rewardStoredPrev : rewardStoredPrev;

            return (returnableAmount, cycle, rewardStoredPrev);
        // We are outside the normal cycle, during time of Illumina sale
        } else if (lastUpdateTimestamp < illuminationTimeStamp && block.timestamp > illuminationTimeStamp && block.timestamp > lastUpdateTimestamp) {

            uint256 returnableAmount = rewardStoredPrev + (rewardPerCycle / 10000) - rewardPaid;
            return (returnableAmount, cycle, rewardStoredPrev);
        // Handle all edge cases
        } else {
            return (rewardStoredPrev, cycle, rewardStoredPrev);
        }
    }
}