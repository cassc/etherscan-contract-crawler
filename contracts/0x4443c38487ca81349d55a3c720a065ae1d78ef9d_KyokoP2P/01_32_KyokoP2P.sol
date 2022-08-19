// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "./LenderToken.sol";
import "./KyokoStorage.sol";
import "./IKyoko.sol";

/**
 * @dev The entrance of P2P business
 */
contract KyokoP2P is
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    PausableUpgradeable,
    KyokoStorage,
    IKyoko
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using Configuration for DataTypes.NFT;

    function initialize(address _lToken) public initializer {
        __Ownable_init();
        __Pausable_init();
        lToken = LenderToken(_lToken);
        //default Handling fee factor is 1%
        fee = 100;
    }

    modifier checkWhiteList(address _address) {
        require(whiteList[_address], "This address is not in the whitelist");
        _;
    }

    modifier checkCollateralStatus(uint256 _depositId) {
        DataTypes.NFT storage _nft = nftMap[_depositId];
        require(!_nft.getRepay() && _nft.getBorrow(), "NFT status wrong");
        _;
    }

    function setPause(bool pause) external onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
        emit SetPause(pause);
    }

    function updateWhiteList(address _address, bool _active)
        external
        whenNotPaused
        onlyOwner
    {
        whiteList[_address] = _active;
        _active ? whiteSet.add(_address) : whiteSet.remove(_address);
        emit UpdateWhiteList(_address, _active);
    }

    function setFee(uint256 _fee) external whenNotPaused onlyOwner {
        require(_fee * 10 <= FEE_PERCENTAGE_BASE, "fee too high");
        fee = _fee;
        emit SetFee(_fee);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721HolderUpgradeable) returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    /**
     * @dev Staking NFT into contracts
     */
    function deposit(
        address _nftAdr,
        uint256 _nftId,
        uint256 _apy,
        uint256 _price,
        uint256 _period,
        uint256 _buffering,
        address _erc20Token,
        string memory _description
    ) external whenNotPaused checkWhiteList(_erc20Token) returns (uint256) {
        require(
            IERC721Upgradeable(_nftAdr) != lToken,
            "the lender token Credential not supported."
        );
        require(
            IERC721Upgradeable(_nftAdr).supportsInterface(0x80ac58cd),
            "Parameter _nftAdr is not ERC721 contract address"
        );

        depositId.increment();
        uint256 currentDepositId = depositId.current();

        nftHolderMap[msg.sender].add(currentDepositId);
        DataTypes.COLLATERAL memory _collateral = DataTypes.COLLATERAL({
            apy: _apy,
            price: _price,
            period: _period,
            buffering: _buffering,
            erc20Token: _erc20Token,
            description: _description
        }); // collateral info
        nftMap[currentDepositId] = DataTypes.NFT({
            holder: msg.sender,
            lender: address(0),
            nftId: _nftId,
            nftAdr: _nftAdr,
            depositId: currentDepositId,
            lTokenId: 0,
            borrowTimestamp: 0,
            emergencyTimestamp: 0,
            repayAmount: 0,
            marks: 0,
            collateral: _collateral
        });

        IERC721Upgradeable(_nftAdr).safeTransferFrom(
            msg.sender,
            address(this),
            _nftId
        );
        open.add(currentDepositId);
        emit Deposit(currentDepositId, _nftId, _nftAdr);
        return currentDepositId;
    }

    /**
     * @dev When your NFT is not lent, you can modify the information
     */
    function modify(
        uint256 _depositId,
        uint256 _apy,
        uint256 _price,
        uint256 _period,
        uint256 _buffering,
        address _erc20Token,
        string memory _description
    ) external whenNotPaused checkWhiteList(_erc20Token) {
        DataTypes.NFT storage _nft = nftMap[_depositId];
        require(
            nftHolderMap[msg.sender].contains(_depositId) &&
                !_nft.getBorrow() &&
                !_nft.getWithdraw(),
            "this _depositId is not your owner"
        );
        // change collateral status
        _nft.collateral.apy = _apy;
        _nft.collateral.price = _price;
        _nft.collateral.period = _period;
        _nft.collateral.buffering = _buffering;
        _nft.collateral.erc20Token = _erc20Token;
        _nft.collateral.description = _description;
        emit Modify(_depositId, msg.sender);
    }

    /**
     * @dev anyone can give you offer on any current NFT
     */
    function addOffer(
        uint256 _depositId,
        uint256 _apy,
        uint256 _price,
        uint256 _period,
        uint256 _buffering,
        address _erc20Token
    ) external whenNotPaused checkWhiteList(_erc20Token) {
        DataTypes.NFT storage _nft = nftMap[_depositId];
        require(!_nft.getBorrow(), "This collateral already borrowed");
        require(!_nft.getWithdraw(), "This collateral already withdrawn.");
        require(!_nft.getRepay(), "Bad parameters:repay.");
        require(!_nft.getLiquidate(), "Bad parameters:liquidate.");

        offerId.increment();
        uint256 currentOfferId = offerId.current();

        uint256 _realPrice = _price.mul(FEE_PERCENTAGE_BASE).div(
            FEE_PERCENTAGE_BASE + fee
        );
        IERC20Upgradeable(_erc20Token).safeTransferFrom(
            address(msg.sender),
            address(this),
            _price
        );
        DataTypes.OFFER memory _off = DataTypes.OFFER({
            apy: _apy,
            price: _realPrice,
            period: _period,
            buffering: _buffering,
            erc20Token: _erc20Token,
            accept: false,
            cancel: false,
            offerId: currentOfferId,
            lTokenId: 0,
            user: msg.sender,
            fee: fee
        });
        depositIdOfferMap[_depositId].add(currentOfferId);
        offerMap[currentOfferId] = _off;
        emit AddOffer(_depositId, msg.sender, currentOfferId);
    }

    /**
     * @dev If your offer is not accepted or cancelled, you can cancel the bid
     */
    function cancelOffer(uint256 _depositId, uint256 _offerId)
        external
        whenNotPaused
    {
        require(
            depositIdOfferMap[_depositId].contains(_offerId),
            "this offer not in the deposit NFT transaction"
        );
        DataTypes.OFFER storage _offer = offerMap[_offerId];
        require(_offer.user == msg.sender, "Not this offer owner"); // Verify token owner
        require(!_offer.accept, "This offer already accepted");
        require(!_offer.cancel, "This offer already cancelled");

        depositIdOfferMap[_depositId].remove(_offerId);
        _offer.cancel = true;

        //When the user cancels the offer, it is calculated according to the fee when the offer was added
        uint256 _totalAmount = _offer
            .price
            .mul(FEE_PERCENTAGE_BASE + _offer.fee)
            .div(FEE_PERCENTAGE_BASE);
        IERC20Upgradeable(_offer.erc20Token).safeTransfer(
            msg.sender,
            _totalAmount
        );

        emit CancelOffer(_depositId, _offerId, msg.sender);
    }

    /**
     * @dev NFT holders can choose an offer to accept
     */
    function acceptOffer(uint256 _depositId, uint256 _offerId)
        external
        whenNotPaused
    {
        require(
            depositIdOfferMap[_depositId].contains(_offerId),
            "this offer not in the deposit NFT transaction"
        );
        require(
            nftHolderMap[msg.sender].contains(_depositId),
            "this depositId is not belong to you."
        );

        DataTypes.OFFER storage _offer = offerMap[_offerId];
        require(!_offer.accept, "This offer already accepted.");
        require(!_offer.cancel, "This offer already cancelled.");

        _offer.accept = true; // change offer status

        DataTypes.NFT storage _nft = nftMap[_depositId];

        // change collateral status
        _nft.collateral.apy = _offer.apy;
        _nft.collateral.price = _offer.price;
        _nft.collateral.period = _offer.period;
        _nft.collateral.buffering = _offer.buffering;
        _nft.collateral.erc20Token = _offer.erc20Token;

        _lend(_depositId, false, _offer.user);

        emit AcceptOffer(_offer.user, msg.sender, _depositId, _offerId);
    }

    /**
     * @dev Users lend directly based on the information released by the NFT holder.
     */
    function lend(
        uint256 _depositId,
        uint256 _apy,
        uint256 _price,
        uint256 _period,
        uint256 _buffering,
        address _erc20Token
    ) external whenNotPaused {
        DataTypes.NFT memory _nft = nftMap[_depositId];
        require(
            _nft.collateral.apy == _apy &&
                _nft.collateral.price == _price &&
                _nft.collateral.period == _period &&
                _nft.collateral.buffering == _buffering &&
                _nft.collateral.erc20Token == _erc20Token,
            "Bad parameters."
        );
        _lend(_depositId, true, msg.sender);
    }

    function _lend(
        uint256 _depositId,
        bool lendMode,
        address offerUser
    ) private {
        DataTypes.NFT storage _nft = nftMap[_depositId];

        require(!_nft.getBorrow(), "This collateral already borrowed.");
        require(!_nft.getWithdraw(), "This collateral already withdrawn.");
        require(!_nft.getRepay(), "Bad parameters:repay.");
        require(!_nft.getLiquidate(), "Bad parameters:liquidate.");

        address _erc20Token = _nft.collateral.erc20Token;
        uint256 price = _nft.collateral.price;
        uint256 totalAmount = price.mul(FEE_PERCENTAGE_BASE + fee).div(
            FEE_PERCENTAGE_BASE
        ); // get lend amount

        if (lendMode) {
            //In the lending mode, first transfer the ERC20 to the current contract
            IERC20Upgradeable(_erc20Token).safeTransferFrom(
                address(msg.sender),
                address(this),
                totalAmount
            );
        }
        //Transfer money to NFT stakers
        IERC20Upgradeable(_nft.collateral.erc20Token).safeTransfer(
            address(_nft.holder),
            price
        );

        uint256 _lTokenId = lToken.mint(offerUser); // mint lToken
        lendMap[_lTokenId] = _depositId;

        _nft.lender = offerUser;
        _nft.lTokenId = _lTokenId; // set collateral lTokenid
        _nft.borrowTimestamp = block.timestamp;

        _nft.setBorrow(true); // change collateral status
        lent.add(_depositId);
        open.remove(_depositId);

        emit Lend(offerUser, _nft.holder, _depositId, _lTokenId);
    }

    /**
     * @dev The NFT stakers pay back
     */
    function repay(uint256 _depositId, uint256 _amount) external {
        DataTypes.NFT storage _nft = nftMap[_depositId];

        require(
            nftHolderMap[msg.sender].contains(_depositId),
            "this depositId is not belong to you."
        );
        require(_nft.getBorrow(), "This collateral is not borrowed.");
        require(!_nft.getRepay(), "This debt already Cleared."); // Debt has clear
        require(!_nft.getLiquidate(), "This debt already liquidated."); // has liquidate

        uint256 _repayAmount = calcInterestRate(_depositId, true); // get repay amount
        require(_amount >= _repayAmount, "Wrong payment amount.");

        IERC20Upgradeable(_nft.collateral.erc20Token).safeTransferFrom(
            address(msg.sender),
            address(this),
            _repayAmount
        );
        _nft.setRepay(true); // change collateral status
        _nft.repayAmount = _repayAmount;
        lent.remove(_depositId);
        emit Repay(_depositId, _repayAmount);
    }

    /**
     * @dev When the NFT stakers pay back the money, he can get back NFT
     */
    function claimCollateral(uint256 _depositId) external  {
        require(
            nftHolderMap[msg.sender].contains(_depositId),
            "this depositId is not belong to you."
        );

        DataTypes.NFT storage _nft = nftMap[_depositId];
        require(
            !_nft.getBorrow() || (_nft.getBorrow() && _nft.getRepay()),
            "This debt is not repay."
        );
        require(!_nft.getWithdraw(), "You have withdrawn this NFT.");
        require(!_nft.getLiquidate(), "This debt already liquidated.");

        _nft.setWithdraw(true);
        open.remove(_depositId);
        lent.remove(_depositId);

        IERC721Upgradeable(_nft.nftAdr).safeTransferFrom(
            address(this),
            msg.sender,
            _nft.nftId
        ); // send collateral to msg.sender
        emit ClaimCollateral(_depositId);
    }

    /**
     * @dev Lenders get their money back, including interest
     */
    function claimERC20(uint256 _lTokenId) external {
        uint256 _depositId = lendMap[_lTokenId];
        DataTypes.NFT storage _nft = nftMap[_depositId];
        require(_lTokenId == _nft.lTokenId, "lTokenId data error.");
        require(
            lToken.ownerOf(_nft.lTokenId) == msg.sender,
            "Not lToken owner"
        ); // Verify token owner
        require(_nft.getRepay(), "This debt is not clear");
        lToken.burn(_nft.lTokenId); // burn lToken
        IERC20Upgradeable(_nft.collateral.erc20Token).safeTransfer(
            msg.sender,
            _nft.repayAmount
        );
        emit ClaimERC20(_lTokenId);
    }

    /**
     * @dev After the expiration date, the NFT pledger still has not repaid the money.
     * The party who paid the money will perform this operation,
     * which will trigger the entry into the liquidation countdown state.
     */
    function executeEmergency(uint256 _depositId)
        external
        whenNotPaused
        checkCollateralStatus(_depositId)
    {
        DataTypes.NFT storage _nft = nftMap[_depositId];
        require(
            lToken.ownerOf(_nft.lTokenId) == msg.sender,
            "Not lToken owner"
        ); // Verify token owner
        require(
            (block.timestamp - _nft.borrowTimestamp) > _nft.collateral.period,
            "Can do not execute emergency."
        ); // An emergency can be triggered after collateral period
        _nft.emergencyTimestamp = block.timestamp; // set collateral emergency timestamp
        emit ExecuteEmergency(_depositId);
    }

    /**
     * @dev Lender performs liquidate operation
     */
    function liquidate(uint256 _depositId)
        external
        whenNotPaused
        checkCollateralStatus(_depositId)
    {
        DataTypes.NFT storage _nft = nftMap[_depositId];
        uint256 _emerTime = _nft.emergencyTimestamp;
        require(_emerTime > 0, "The collateral has not been in an emergency");
        require(
            (block.timestamp - _emerTime) > _nft.collateral.buffering,
            "Can do not liquidate."
        );
        require(
            lToken.ownerOf(_nft.lTokenId) == msg.sender,
            "Not lToken owner"
        ); // Verify token owner
        lToken.burn(_nft.lTokenId); // burn lToken
        _nft.setLiquidate(true);
        lent.remove(_depositId);
        IERC721Upgradeable(_nft.nftAdr).safeTransferFrom(
            address(this),
            msg.sender,
            _nft.nftId
        ); // send collateral to lender
        emit Liquidate(_depositId);
    }

    function calcInterestRate(uint256 _depositId, bool _isRepay)
        public
        view
        returns (uint256 repayAmount)
    {
        uint256 base = _isRepay ? 100 : 101;
        DataTypes.NFT storage _nft = nftMap[_depositId];
        require(
            _nft.getBorrow() && !_nft.getRepay() && !_nft.getLiquidate(),
            "No interest."
        );
        if (_nft.borrowTimestamp == 0) {
            return repayAmount;
        }
        uint256 _loanSeconds = block.timestamp - _nft.borrowTimestamp; // loan period
        uint256 _secondsInterest = _nft.collateral.apy.mul(10**16).div(
            ONE_YEAR
        );
        uint256 _totalInterest = (_loanSeconds *
            _secondsInterest *
            _nft.collateral.price) / 10**18; // total interest
        repayAmount = _totalInterest.add(
            _nft.collateral.price.mul(base).div(100)
        );
    }

    function getWhiteSet() public view returns (address[] memory) {
        return whiteSet.values();
    }

    function getNftHolderMap(address holder)
        public
        view
        returns (uint256[] memory)
    {
        return nftHolderMap[holder].values();
    }

    function getDepositIdOfferMap(uint256 depositId)
        public
        view
        returns (uint256[] memory)
    {
        return depositIdOfferMap[depositId].values();
    }

    function getState(uint256 _depositId)
        public
        view
        returns (
            bool,
            bool,
            bool,
            bool
        )
    {
        DataTypes.NFT storage _nft = nftMap[_depositId];
        return _nft.getState();
    }

    // function transferFee(
    //     address asset,
    //     address to,
    //     uint256 amount
    // ) public onlyOwner {
    //     IERC20Upgradeable(asset).safeTransfer(to, amount);
    // }

    function getEffectiveNftHolderDepositId(address holder)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory depositIdArray = nftHolderMap[holder].values();
        if (depositIdArray.length == 0) {
            return depositIdArray;
        }
        uint256 arrayLength = depositIdArray.length;
        uint256[] memory resultDepositIdArray = new uint256[](arrayLength);
        for (uint256 i = 0; i < depositIdArray.length; i++) {
            uint256 tempDepositId = depositIdArray[i];
            (
                bool borrowState,
                bool repayState,
                bool withdrawState,
                bool liquidateState
            ) = getState(tempDepositId);

            // No one has come to borrow the NFT yet
            bool case1 = !borrowState && !withdrawState;
            // NFT during normal loan period
            bool case2 = borrowState &&
                !repayState &&
                !liquidateState &&
                !withdrawState;
            // The NFT stakers has repay ERC20 token, but has not yet withdraw it
            bool case3 = borrowState &&
                repayState &&
                !liquidateState &&
                !withdrawState;
            if (case1 || case2 || case3) {
                resultDepositIdArray[i] = tempDepositId;
            }
        }
        return resultDepositIdArray;
    }

    /**
     * @dev get the depositId array of the open state
     */
    function getOpen() public view returns (uint256[] memory) {
        return open.values();
    }

    /**
     * @dev get the depositId array of the lent state
     */
    function getLent() public view returns (uint256[] memory) {
        return lent.values();
    }
}