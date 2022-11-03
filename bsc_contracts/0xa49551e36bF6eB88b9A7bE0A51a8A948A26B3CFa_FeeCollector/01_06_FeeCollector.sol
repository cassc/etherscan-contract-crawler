// SPDX-License-Identifier: MIT

pragma solidity =0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./FeeCollectorStorage.sol";


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {

    /**
  * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function firstHolder(uint256 tokenId) external view returns(address);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);
}


contract FeeCollector is FeeCollectorStorage, ReentrancyGuard, Ownable{

    event SetFeeRatio(uint256 oldFeeRatio, uint256 newFeeRatio);
    event SetCapitalPool(address oldCapitalPool, address newCapitalPool);
    event SetTechnicalSupport(address oldTechnicalSupport, address newTechnicalSupport);
    event SetTrade(address oldTrade, address newTrade);
    event NFTHolderFee(address token, uint256 id, address owner, uint256 royalty);
    event PoolFeeWithdraw(address token, uint256 fee);
    event TechnologyFeeWithdraw(address token, uint256 fee);
    event WithdrawFee(address token, uint256 totalAvailable, uint256 available);
    event MultipleWithdrawFee(address token, uint256 totalReceive);

    using SafeMath for uint256;

    constructor(address _capitalPool, address _technicalSupport, uint256 _feeRatio){
        capitalPool = _capitalPool;
        technicalSupport = _technicalSupport;
        feeRatio = _feeRatio;
    }


    function serviceCharge(address offerToken, uint256 identifier, address quoteToken, uint256 quoteAmount) external onlyTrade returns(address, uint256, address, uint256){
        address nftHolder = IERC721(offerToken).firstHolder(identifier);
        require(nftHolder != address(0), "The address of the first NFT holder does not exist");

        uint256 fee = quoteAmount.mul(1e18).div(feeRatio);

        uint256 holderFee = fee.mul(holderFeeRatio).div(1e18);
        uint256 poolFeeDividend = fee.mul(capitalPoolFeeRatio).div(1e18);
        // technicalSupportFee += fee.mul(technicalSupportFeeRatio).div(1e18);
        uint256 genesisDividend = fee.mul(genesisFeeRatio).div(1e18);
        uint256 jointDividend = fee.mul(jointFeeRatio).div(1e18);

        uint256 feeSum = holderFee.add(poolFeeDividend).add(genesisDividend).add(jointDividend);
        technicalSupportFee += quoteAmount.sub(feeSum);

        capitalPoolFee += poolFeeDividend;
        totalNftFee[genesis] += genesisDividend;
        totalNftFee[joint] += jointDividend;

        totalAmount += quoteAmount;

        IERC20(quoteToken).transfer(nftHolder, holderFee);
        emit NFTHolderFee(offerToken, identifier, nftHolder, holderFee);
        return (offerToken, identifier, quoteToken, quoteAmount);
    }

    function poolFeeWithdraw() external returns(address, uint256){
        require(msg.sender == capitalPool, "The caller is not the fund pool address");
        bool success = IERC20(quoteToken).transfer(msg.sender, capitalPoolFee);
        if(success) capitalPoolFee = 0;
        emit PoolFeeWithdraw(quoteToken, capitalPoolFee);
        return (quoteToken, capitalPoolFee);
    }

    function technologyFeeWithdraw() external returns(address, uint256){
        require(msg.sender == technicalSupport, "The caller is not a technical support address");
        bool success = IERC20(quoteToken).transfer(msg.sender, technicalSupportFee);
        if(success) technicalSupportFee = 0;
        emit TechnologyFeeWithdraw(quoteToken, technicalSupportFee);
        return (quoteToken, technicalSupportFee);
    }

    function withdrawFee(address nft, uint256 tokenId) external nonReentrant returns(address, uint256, uint256){
        address owner = IERC721(nft).ownerOf(tokenId);
        require(owner == msg.sender, "This NFT card is not yours");

        uint256 totalSupply = IERC721(nft).totalSupply();
        uint256 dividend = totalNftFee[nft].div(totalSupply);

        uint256 received = receivedFee[nft][tokenId];
        uint256 fundsAvailable = dividend.sub(received);
        require(fundsAvailable > 0, "No handling fee dividends to be claimed");

        bool success = IERC20(quoteToken).transfer(msg.sender, fundsAvailable);
        if(success) receivedFee[nft][tokenId] += fundsAvailable;
        emit WithdrawFee(quoteToken, dividend, fundsAvailable);
        return (quoteToken, dividend, fundsAvailable);
    }

    function multipleWithdrawFee(address[] calldata nft, uint256[] calldata tokenId) external nonReentrant returns(bool){
        require(nft.length > 0, "NFT array length is less than 0");
        uint256 _totalAmount;
        for(uint i; i < nft.length; i++){
            address owner = IERC721(nft[i]).ownerOf(tokenId[i]);
            require(owner == msg.sender, "This NFT card is not yours");

            uint256 totalSupply = IERC721(nft[i]).totalSupply();
            uint256 dividend = totalNftFee[nft[i]].div(totalSupply);

            uint256 received = receivedFee[nft[i]][tokenId[i]];
            uint256 fundsAvailable = dividend.sub(received);
            _totalAmount += fundsAvailable;
            receivedFee[nft[i]][tokenId[i]] += fundsAvailable;
        }
        bool success = IERC20(quoteToken).transfer(msg.sender, _totalAmount);

        emit MultipleWithdrawFee(quoteToken, _totalAmount);
        return success;
    }

    function _setFeeRatio(uint256 newFeeRatio) external onlyOwner {
        require(newFeeRatio > 0, "Parameter error");
        uint256 old = feeRatio;
        feeRatio = newFeeRatio;
        emit SetFeeRatio(old, newFeeRatio);
    }

    function _setHolderFeeRatio(uint256 newHolderFeeRatio) external onlyOwner {
        require(newHolderFeeRatio > 0, "Parameter error");
        uint256 old = holderFeeRatio;
        holderFeeRatio = newHolderFeeRatio;
        emit SetFeeRatio(old, newHolderFeeRatio);
    }

    function _setCapitalPoolFeeRatio(uint256 newCapitalPoolFeeRatio) external onlyOwner {
        require(newCapitalPoolFeeRatio > 0, "Parameter error");
        uint256 old = capitalPoolFeeRatio;
        capitalPoolFeeRatio = newCapitalPoolFeeRatio;
        emit SetFeeRatio(old, newCapitalPoolFeeRatio);
    }

    function _setTechnicalSupportFeeRatio(uint256 newTechnicalSupportFeeRatio) external onlyOwner {
        require(newTechnicalSupportFeeRatio > 0, "Parameter error");
        uint256 old = technicalSupportFeeRatio;
        technicalSupportFeeRatio = newTechnicalSupportFeeRatio;
        emit SetFeeRatio(old, newTechnicalSupportFeeRatio);
    }

    function _setGenesisFeeRatio(uint256 newGenesisFeeRatio) external onlyOwner {
        require(newGenesisFeeRatio > 0, "Parameter error");
        uint256 old = genesisFeeRatio;
        genesisFeeRatio = newGenesisFeeRatio;
        emit SetFeeRatio(old, newGenesisFeeRatio);
    }

    function _setJointFeeRatio(uint256 newJointFeeRatio) external onlyOwner {
        require(newJointFeeRatio > 0, "Parameter error");
        uint256 old = jointFeeRatio;
        jointFeeRatio = newJointFeeRatio;
        emit SetFeeRatio(old, newJointFeeRatio);
    }

    function _setCapitalPool(address newCapitalPool) external onlyOwner {
        require(newCapitalPool != address(0), "Capital Pool cannot be set to zero address");
        address old = capitalPool;
        capitalPool = newCapitalPool;
        emit SetCapitalPool(old, newCapitalPool);
    }

    function _setTechnicalSupport(address newTechnicalSupport) external onlyOwner {
        require(newTechnicalSupport != address(0), "Technical Support cannot be set to zero address");
        address old = technicalSupport;
        technicalSupport = newTechnicalSupport;
        emit SetTechnicalSupport(old, newTechnicalSupport);
    }

    function _setTrade(address newTrade) external onlyOwner {
        require(newTrade != address(0), "Trade cannot be set to zero address");
        address old = trade;
        trade = newTrade;
        emit SetTrade(old, newTrade);
    }

    function amountAvailable(address nft, uint256 tokenId) external view returns(uint256) {
        uint256 totalSupply = IERC721(nft).totalSupply();
        uint256 dividend = totalNftFee[nft].div(totalSupply);
        uint256 received = receivedFee[nft][tokenId];
        uint256 fundsAvailable = dividend.sub(received);
        return fundsAvailable;
    }

    function amountAvailableList(address[] calldata nft, uint256[] calldata tokenId) external view returns(address[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory total = new uint256[](nft.length);
        for(uint i; i < nft.length; i++){
            uint256 totalSupply = IERC721(nft[i]).totalSupply();
            uint256 dividend = totalNftFee[nft[i]].div(totalSupply);
            uint256 received = receivedFee[nft[i]][tokenId[i]];
            uint256 fundsAvailable = dividend.sub(received);
            total[i] = fundsAvailable;
        }
        return (nft, tokenId, total);
    }

    function balanceOf() external view returns(uint256) {
        return IERC20(quoteToken).balanceOf(address(this));
    }

    modifier onlyTrade(){
        require(msg.sender == trade, "caller is not the trade address");
        _;
    }

}