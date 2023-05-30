// SPDX-License-Identifier: MIT
// ENVELOP (NIFTSY) protocol for NFT. Wrapper & Farming contract
pragma solidity 0.8.7;

import "./WrapperWithERC20Collateral.sol";
import "../interfaces/IERC721Mintable.sol";

/**
 * @title ERC-721 Non-Fungible Token Wrapper 
 * @dev For wrpap and Rewarf farming. ERC20 reward must be on this contract balance
 * !!!!!!!!! Important  !!!!!!!!!!!!!!!!!!!!!!!!!!!
 * Please Don't add farming token in erc20 collateral whitelist
 */
contract WrapperFarming is WrapperWithERC20Collateral {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;
    using Strings for uint160;
    using Strings for uint256;
    
    struct RewardSettings {
        uint256 period;
        uint256 rewardPercent; // multiplyed by 100, 1%-100, 12$-1200,99%-
    }

    struct NFTReward {
        uint256 stakedDate;
        uint256 harvestedAmount;
    }

    bool public isDepricated;
    uint8 public MAX_SETTINGS_SLOTS = 10;
    address public defaultFarmingToken;
    
    // from farming token address  to settings(reward points) 
    mapping(address => RewardSettings[]) public rewardSettings;
    mapping(uint256 => NFTReward) public rewards;

    event SettingsChanged(address farmingToken, uint256 slotId);
    event Harvest(uint256 tokenId, address farmingToken, uint256 amount);
    event Staked(uint256 tokenId, address farmingToken, uint256 amount);

    constructor (address _erc20, address _defaultFarmingToken ) 
        WrapperWithERC20Collateral(_erc20) 
    {
        defaultFarmingToken = _defaultFarmingToken;
    }
    

    /// !!!!For gas safe this low levelfunction has NO any check before wrap
    /// So you have NO warranty to do Unwrap well
    function WrapForFarming(
        address  _receiver,
        ERC20Collateral memory _erc20Collateral,
        uint256 _unwrapAfter
    ) public payable 
    {
        require(_receiver != address(0), "No zero address");
        require(!isDepricated, "Pool is depricated for new stakes");
        // 1.topup wrapper contract with erc20 that would be added in collateral
        IERC20(_erc20Collateral.erc20Token).safeTransferFrom(
            msg.sender, 
            address(this), 
            _erc20Collateral.amount
        );

        // 2.Mint wrapped NFT for receiver and populate storage
        lastWrappedNFTId += 1;
        _mint(_receiver, lastWrappedNFTId);
        wrappedTokens[lastWrappedNFTId] = NFT(
            address(0), // _original721, 
            0, // _tokenIds[i], 
            msg.value,        // native blockchain asset
            0,                // accumalated fee token
            _unwrapAfter,     // timelock
            0,                //_transferFee,
            address(0),       // _royaltyBeneficiary,
            0,                //_royaltyPercent,
            0,                //_unwraptFeeThreshold,
            address(0),       //_transferFeeToken,
            AssetType.UNDEFINED,
            0
        );

        // 3.Add erc20 collateral
        ERC20Collateral[] storage coll = erc20Collateral[lastWrappedNFTId];
        coll.push(ERC20Collateral({
            erc20Token: _erc20Collateral.erc20Token, 
            amount: _erc20Collateral.amount
        }));
        emit Wrapped(address(0), 0, lastWrappedNFTId);

        // 4. Register farming
        NFTReward storage r = rewards[lastWrappedNFTId];
        r.stakedDate = block.timestamp;
        emit Staked(lastWrappedNFTId, _erc20Collateral.erc20Token, _erc20Collateral.amount);
    }

    function harvest(uint256 _wrappedTokenId, address _erc20) public {
        // We dont need chec ownership because reward will  be added to wNFT
        // And unWrap this nft can only owner
        require(ownerOf(_wrappedTokenId) == msg.sender, "Only for wNFT holder");
        uint256 rewardAmount = getAvailableRewardAmount(_wrappedTokenId, _erc20);
        if (rewardAmount > 0) {
            NFTReward storage thisNFTReward = rewards[_wrappedTokenId]; 
            ERC20Collateral[] storage e = erc20Collateral[_wrappedTokenId];
            for (uint256 i = 0; i < e.length; i ++) {
                if (e[i].erc20Token == _erc20) {
                    e[i].amount += rewardAmount;
                    //thisNFTReward.harvestedAmount += rewardAmount;
                    // Reset date for lazy ReStake  
                    thisNFTReward.stakedDate = block.timestamp;
                    break;
                }
            }
            emit Harvest(_wrappedTokenId, _erc20, rewardAmount);
        }
    }

    function getAvailableRewardAmount(uint256 _tokenId, address _erc20) public view returns (uint256 rewardAccrued) {
        uint256 timeInStake = block.timestamp - rewards[_tokenId].stakedDate;
        rewardAccrued = _getPercentByPeriod(timeInStake, _erc20)
            * getERC20CollateralBalance(_tokenId, _erc20)  / 10000;
        return rewardAccrued; 
    }

    function getCurrenntAPYByTokenId(uint256 _tokenId, address _erc20) public view returns (uint256 percents) {
        uint256 timeInStake = block.timestamp - rewards[_tokenId].stakedDate;
        percents = _getPercentByPeriod(timeInStake, _erc20);
        return percents; 
    }

    function getPlanAPYByTokenId(uint256 _tokenId, address _erc20) public view returns (uint256 percents) {
        uint256 timeInStake;
        if (wrappedTokens[_tokenId].unwrapAfter <= rewards[_tokenId].stakedDate) {
              // Case when first harvest was done  after unwrapAfter
              timeInStake = block.timestamp - rewards[_tokenId].stakedDate;
            } else {
              timeInStake = wrappedTokens[_tokenId].unwrapAfter - rewards[_tokenId].stakedDate;
            }
        percents = _getPercentByPeriod(timeInStake, _erc20);
        return percents; 
    }

    function getRewardSettings(address _farmingTokenAddress)
        external 
        view 
        returns (RewardSettings[] memory settings) 
    {
        settings = rewardSettings[_farmingTokenAddress];
        return settings;
    }

    function name() public view virtual override(ERC721) returns (string memory) {
        return 'ENVELOP wNFT Farming';
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override(ERC721) returns (string memory) {
        return 'wNFTF';
    }

    function _baseURI() internal view  override(ERC721) returns (string memory) {
        return 'https://envelop.is/distribmetadata/';
    }

    ////////////////////////////////////////////////////////////////
    //////////     Admins                                     //////
    ////////////////////////////////////////////////////////////////

    function setRewardSettings(
        address _erc20, 
        uint256 _settingsSlotId, 
        uint256 _period, 
        uint256 _percent
    ) external onlyOwner {
        
        require(rewardSettings[_erc20].length > 0, "There is no settings for this token");
        RewardSettings[] storage set = rewardSettings[_erc20];
        set[_settingsSlotId].period = _period;
        emit SettingsChanged(_erc20, _settingsSlotId);
    }

    function addRewardSettingsSlot(
        address _erc20, 
        uint256 _period, 
        uint256 _percent
    ) external onlyOwner {

        require(rewardSettings[_erc20].length < MAX_SETTINGS_SLOTS - 1, "Too much settings slot");
        RewardSettings[] storage set = rewardSettings[_erc20];
        set.push(RewardSettings({
            period: _period,
            rewardPercent: _percent
        }));
        emit SettingsChanged(_erc20, set.length-1);
    }

    function setPoolState(bool _isDepricate) external onlyOwner {
        isDepricated = _isDepricate;
    }
    
    
    
    /**
     * @dev Function returns tokenURI of **underline original token** 
     *
     * @param _tokenId id of protocol token (new wrapped token)
     */
    function tokenURI(uint256 _tokenId) public view virtual override 
        returns (string memory) 
    {
        NFT storage nft = wrappedTokens[_tokenId];
        if (nft.tokenContract != address(0)) {
            return IERC721Metadata(nft.tokenContract).tokenURI(nft.tokenId);
        } else {
            return string(abi.encodePacked(
            _baseURI(),
            uint160(address(this)).toHexString(),
            "/", _tokenId.toString())
            );
        }    
        
    }


    ////////////////////////////////////////////////////////////////
    //    Internals                                           //////
    ////////////////////////////////////////////////////////////////
    function _getPercentByPeriod(uint256 _period, address _erc20) internal view returns (uint256 percents) {
        if (rewardSettings[_erc20][0].period > _period) {
            //case when time too short
            percents = 0;
            return percents;
        } 
        for (uint8 i = 0; i < rewardSettings[_erc20].length; i ++) {
            if (rewardSettings[_erc20][i].period <= _period 
                &&  rewardSettings[_erc20][i + 1].period > _period) {
                // Case when  user have reward apprpriate current stake time
                percents = rewardSettings[_erc20][i].rewardPercent;
                break;
            } else {
                //Case when next slot is last
                if (i + 2 == rewardSettings[_erc20].length) {
                    // Case when user have MAX  percent (last  setting slot)
                    percents = rewardSettings[_erc20][i + 1].rewardPercent;
                    break;
                }
            }
        }
        return percents;

    }
}