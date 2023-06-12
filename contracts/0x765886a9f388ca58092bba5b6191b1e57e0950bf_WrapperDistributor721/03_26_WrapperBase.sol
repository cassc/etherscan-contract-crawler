// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol for NFT. Wrapper - main protocol contract
pragma solidity ^0.8.6;

import "Ownable.sol";
import "ERC721Enumerable.sol";
import "SafeERC20.sol";
import "ReentrancyGuard.sol";
import "TechToken.sol";
import "ITechToken.sol";
import "IFeeRoyaltyCharger.sol";


/**
 * @title ERC-721 Non-Fungible Token Wrapper
 * @dev For wrpap existing ERC721 and ERC1155(now only 721)
 */
contract WrapperBase is ERC721Enumerable, Ownable, ReentrancyGuard, IFeeRoyaltyCharger {
    using SafeERC20 for IERC20;

    enum AssetType {UNDEFINED, ERC20, ERC721, ERC1155}

    struct NFT {
        address tokenContract;      //Address of wrapping token  contract
        uint256 tokenId;            //Wrapping tokenId
        uint256 backedValue;        //ETH
        uint256 backedTokens;       //native project tokens
        uint256 unwrapAfter;        //Freez date
        uint256 transferFee;        //transferFee amount with decimals i.e. 20e18
        address royaltyBeneficiary; //Royalty payments receiver
        uint256 royaltyPercent;     //% from transferFee
        uint256 unwraptFeeThreshold;//unwrap possiple only after backedTokens achive this amount
        address transferFeeToken;   //user can define transfer fee token contract from whitelist
        AssetType asset;            //wrapped Asset type
        uint256 balance;            //wrapping balance for erc 1155
    }

    struct ListItem { 
        bool enabledForCollateral;
        address transferFeeModel;
        bool disabledForWrap;
    }

    
    uint256 constant public MAX_ROYALTY_PERCENT = 50;
    uint256 constant public MAX_TIME_TO_UNWRAP = 100 * 365 days;
    uint256 constant public MAX_FEE_THRESHOLD_PERCENT = 1; //percent from project token totalSupply 

    uint256 public protocolFee = 0;
    uint256 public chargeFeeAfter = type(uint256).max;
    uint256 public protocolFeeRaised;

    address public projectToken;
    address public protocolFeeToken;
    
    uint256 public lastWrappedNFTId; 

    // Map from wrapped token id => NFT record 
    mapping(uint256 => NFT) public wrappedTokens; //Private in Production

     // Map from conatrct address to  enabled-as-collateral or blacklisted 
    mapping(address => ListItem) public partnersTokenList;

    

    event Wrapped(
        address underlineContract, 
        uint256 tokenId, 
        uint256 indexed wrappedTokenId
    );

    event UnWrapped(
        uint256 indexed wrappedId, 
        address indexed owner, 
        uint256 nativeCollateralAmount,
        uint256 feeAmount 
    );
    event NewFee(uint256 feeAmount, uint256 startDate);
    event NiftsyProtocolTransfer(
        uint256 indexed wrappedTokenId, 
        address indexed royaltyBeneficiary,
        uint256 transferFee, 
        uint256 royalty,
        address feeToken 
    );

    constructor(address _erc20) ERC721("ENVELOP Wrapped NFT Distributor", "wNFT") {
        require(_erc20 != address(0), "ProjectToken cant be zero value");
        projectToken = _erc20; 
    }

    /**
     * @dev DEPRICTAED method due
     * @dev Function for wrap existing ERC721 
     *
     * @param _underlineContract address of native NFT contract
     * @param _tokenId id of NFT that need to be wraped
     * @param _unwrapAfter Unix time value after that token can be unwrapped  
     * @param _transferFee transferFee amount of projectToken with decimals i.e. 20e18 
     * @param _royaltyBeneficiary - address for royalty transfers
     * @param _royaltyPercent - integer 1..100, not more then MAX_ROYALTY_PERCENT
     * @param _unwraptFeeThreshold - token amounts in baccked fee for unwrap enable
     * @param _transferFeeToken - token address for fee and royalty settlemnet. By default
     * tech virtual project token 
     * @return uint256 id of new wrapped token that represent old
     */
    function wrap721(
        address _underlineContract, 
        uint256 _tokenId, 
        uint256 _unwrapAfter,
        uint256 _transferFee,
        address _royaltyBeneficiary,
        uint256 _royaltyPercent,
        uint256 _unwraptFeeThreshold,
        address _transferFeeToken
    ) 
        external 
        payable
        returns (uint256) 
    {
        
        /////////////////Sanity checks////////////////////////
        //0. Check blacklist for wrapping NFT
        require (
                !partnersTokenList[_underlineContract].disabledForWrap,
                "This NFT is blacklisted for wrap" 
        );

        //1. ERC allowance
        // require(
        //     IERC721(_underlineContract).getApproved(_tokenId) == address(this), 
        //     "Please call approve in your NFT contract"
        // );

        //2. Logic around transfer fee
        if  (_transferFee > 0) {
            if (_royaltyPercent > 0) {
                require(_royaltyPercent <= MAX_ROYALTY_PERCENT, "Royalty percent too big");
                require(_royaltyBeneficiary != address(0), "Royalty to zero address");
            }
            

        } else {
            require(_royaltyPercent == 0, "Royalty source is transferFee");
            require(_royaltyBeneficiary == address(0), "No Royalty without transferFee");
            require(_unwraptFeeThreshold == 0, "Cant set Threshold without transferFee");

        }

        //3. MAX time to UNWRAP
        require( _unwrapAfter <= block.timestamp + MAX_TIME_TO_UNWRAP,
            "Too long Wrap"
        );

        //4. For custom transfer fee token lets check MAX_FEE_THRESHOLD_PERCENT
        if  (_transferFeeToken != address(0) && _transferFeeToken != projectToken) { 
            require (
                partnersTokenList[_transferFeeToken].enabledForCollateral,
                "This transferFee token is not enabled" 
            );

            require(
                _unwraptFeeThreshold  <
                IERC20(_transferFeeToken).totalSupply() * MAX_FEE_THRESHOLD_PERCENT / 100,
                "Too much threshold"
            );

            
        }
        //////////////////////////////////////////////////////
        //Protocol fee can be not zero in the future       //
        if  (_getProtocolFeeAmount() > 0) {
            require(
                _chargeFee(msg.sender, _getProtocolFeeAmount()), 
                "Cant charge protocol fee"
            );
            protocolFeeRaised += _getProtocolFeeAmount();
        }

        ////////////////////////
        ///   WRAP LOGIC    ////
        IERC721(_underlineContract).transferFrom(msg.sender, address(this), _tokenId);
        lastWrappedNFTId += 1;
        _mint(msg.sender, lastWrappedNFTId);
        wrappedTokens[lastWrappedNFTId] = NFT(
            _underlineContract, 
            _tokenId, 
            msg.value, 
            0, 
            _unwrapAfter, 
            _transferFee,
            _royaltyBeneficiary,
            _royaltyPercent,
            _unwraptFeeThreshold,
            _transferFeeToken,
            AssetType.ERC721,
            0

        );
        emit Wrapped(_underlineContract, _tokenId, lastWrappedNFTId);
        return lastWrappedNFTId;
    }

    /**
     * @dev Function add native(eth, bnb) collateral to wrapped token
     *
     * @param _wrappedTokenId id of protocol token fo add
     */
    function addNativeCollateral(uint256 _wrappedTokenId) external payable {
        require(ownerOf(_wrappedTokenId) != address(0));
        NFT storage nft = wrappedTokens[_wrappedTokenId];
        nft.backedValue += msg.value;
    }

    /**
     * @dev Function for unwrap protocol token. If wrapped  NFT
     * has many erc20 collateral tokens it possible call this method
     * more than once, until unwrapped
     *
     * @param _tokenId id of protocol token to unwrapp
     */
    function unWrap721(uint256 _tokenId) external nonReentrant {

        ///////////////////////////////////////////////
        ////    Base Protocol checks                ///
        ///////////////////////////////////////////////
        //1. Only token owner can UnWrap
        require(ownerOf(_tokenId) == msg.sender, 'Only owner can unwrap it!');
        //storoge did not work because there is no this var after delete
        NFT memory nft = wrappedTokens[_tokenId];
        
        //2. Time lock check
        if  (nft.unwrapAfter != 0) {
            require(nft.unwrapAfter <= block.timestamp, "Cant unwrap before day X");    
        }
        
        //3. Fee accumulated check
        if (nft.unwraptFeeThreshold > 0){
            require(nft.backedTokens >= nft.unwraptFeeThreshold, "Cant unwrap due Fee Threshold");
        }
        
        ///////////////////////////////////////////////
        ///  Place for hook                        ////
        ///////////////////////////////////////////////

        if (!_beforeUnWrapHook(_tokenId)) {
            return;
        }
        
        /////////////////////////////////////////////// 
        ///  Main UnWrap Logic                   //////
        ///////////////////////////////////////////////
        _burn(_tokenId);
        if (nft.asset == AssetType.ERC721) {
            IERC721(nft.tokenContract).transferFrom(address(this), msg.sender, nft.tokenId);
        }
        delete wrappedTokens[_tokenId];
        //Return backed ether
        if  (nft.backedValue > 0) {
            address payable toPayable = payable(msg.sender);
            toPayable.transfer(nft.backedValue);
        }
        //Return backed tokens
        if  (nft.backedTokens > 0) {
            if  (nft.transferFeeToken == address(0)) {
                IERC20(projectToken).transfer(msg.sender, nft.backedTokens);
            } else {
                IERC20(nft.transferFeeToken).safeTransfer(msg.sender, nft.backedTokens);
            }
        }
        
        emit UnWrapped(
            _tokenId, 
            msg.sender, 
            nft.backedValue,
            nft.backedTokens 
        );
    }

    
    /**
     * @dev Function is part of transferFeeModel interface
     * for charge fee in tech protokol Token 
     *
     */
    function chargeTransferFeeAndRoyalty(
        address from, 
        address to, 
        uint256 transferFee, 
        uint256 royaltyPercent, 
        address royaltyBeneficiary,
        address _transferFeeToken
    ) external
      override 
      returns (uint256 feeIncrement)
    {
        require(msg.sender == address(this), "Wrapper only");
        uint256 rAmount = royaltyPercent * transferFee / 100;
        ITechToken(projectToken).mint(address(this), transferFee - rAmount);
        if (rAmount > 0) {
            ITechToken(projectToken).mint(royaltyBeneficiary, rAmount);    
        }
        return transferFee - rAmount;
    }

    
    /**
     * @dev Function returns tokenURI of **underline original token** 
     *
     * @param _tokenId id of protocol token (new wrapped token)
     */
    function tokenURI(uint256 _tokenId) public view override virtual returns (string memory) {
        NFT storage nft = wrappedTokens[_tokenId];
        return IERC721Metadata(nft.tokenContract).tokenURI(nft.tokenId);
    }

    /**
     * @dev Function returns tuple with accumulated amounts of 
     * native chain collateral(eth, bnb,..) and transfer Fee 
     *
     * @param _tokenId id of protocol token (new wrapped token)
     */
    function getTokenValue(uint256 _tokenId) external view returns (uint256, uint256) {
        NFT storage nft = wrappedTokens[_tokenId];
        return (nft.backedValue, nft.backedTokens);
    }

    /**
     * @dev Function returns structure with all data about
     * new protocol token
     *
     * @param _tokenId id of protocol token (new wrapped token)
     */
    function getWrappedToken(uint256 _tokenId) external view returns (NFT memory) {
        return wrappedTokens[_tokenId];
    }

        
    /////////////////////////////////////////////////////////////////////
    //                    Admin functions                              //
    /////////////////////////////////////////////////////////////////////
    function setFee(uint256 _fee, uint256 _startDate, address _protocolFeeToken) external onlyOwner {
        require(_protocolFeeToken != address(0), "No zero address");
        protocolFee = _fee;
        chargeFeeAfter = _startDate;
        protocolFeeToken = _protocolFeeToken;
        emit NewFee(_fee, _startDate);
    }

    function editPartnersItem (
        address _contract, 
        bool _isCollateral, 
        address _transferFeeModel, 
        bool _isBlackListed 
    ) 
        external 
        onlyOwner 
    {
        partnersTokenList[_contract] = ListItem(
            _isCollateral, _transferFeeModel, _isBlackListed
        );

    }


    /////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////////////
    /////////////   Internals     ///////////////////////////////////////
    /////////////////////////////////////////////////////////////////////
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
        internal 
        virtual 
        override 
    {
        super._beforeTokenTransfer(from, to, tokenId);
        //Not for mint and burn
        if (to != address(0) && from !=address(0)) {
            NFT storage nft = wrappedTokens[tokenId];
            //Transfer fee charge
            if  (nft.transferFee > 0) {
                address feeCharger = partnersTokenList[nft.transferFeeToken].transferFeeModel;

                // If there is no custom fee&royalty model then use
                // tech virtual protokol token
                if (feeCharger == address(0)) { 
                    feeCharger = address(this); 
                }

                uint256 feeinc = IFeeRoyaltyCharger(feeCharger).chargeTransferFeeAndRoyalty(
                    from, 
                    to, 
                    nft.transferFee, 
                    nft.royaltyPercent, 
                    nft.royaltyBeneficiary,
                    nft.transferFeeToken
                ); 
                nft.backedTokens += feeinc;
                
                emit NiftsyProtocolTransfer(
                    tokenId, 
                    nft.royaltyBeneficiary, 
                    nft.transferFee, 
                    nft.transferFee - feeinc, 
                    nft.transferFeeToken
                );
            }
        }
    }

    /**
     * @dev Function charge fee in project token  
     *
     * @param _payer fee payer, must have non zero balance in project token
     * @param _amount fee amount for charge 
     */
    function _chargeFee(address _payer, uint256 _amount) internal returns(bool) {
        require(
            IERC20(protocolFeeToken).balanceOf(_payer) >= _amount, 
                    "insufficient protocol fee token balance for fee"
        );
        IERC20(protocolFeeToken).transferFrom(_payer, address(this), _amount);
        return true;
    }

    /**
     * @dev This hook may be overriden in inheritor contracts for extend
     * base functionality.
     *
     * @param _tokenId -wrapped token
     * 
     * must returna true for success unwrapping enable 
     */
    function _beforeUnWrapHook(uint256 _tokenId) internal virtual returns (bool){
        return true;
    }

    function _getProtocolFeeAmount() internal view returns (uint256) {
        if (block.timestamp >= chargeFeeAfter) {
            return protocolFee;
        } else {
            return 0;
        }
    }

}