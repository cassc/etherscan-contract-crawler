// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// TRUFFLE
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SuperNFTVestStream {
    using SafeMath for uint256;
    using Address for address;

    address public tokenAddress;
    address public nftAddress;

    event Claimed(
        address owner,
        uint256 nftId,
        address beneficiary,
        uint256 amount,
        uint256 index
    );
    event ClaimCreated(
        address owner,
        uint256 nftId,
        uint256 totalAmount,
        uint256 index
    );

    struct Claim {
        address owner;
        uint256 nftId;
        uint256[] timePeriods;
        uint256[] tokenAmounts;
        uint256 totalAmount;
        uint256 amountClaimed;
        uint256 periodsClaimed;
    }
    Claim[] private claims;

    struct StreamInfo {
        uint256 startTime;
        bool notOverflow;
        uint256 startDiff;
        uint256 diff;
        uint256 amountPerBlock;
        uint256[] _timePeriods;
        uint256[] _tokenAmounts;
    }

    mapping(address => uint256[]) private _ownerClaims;
    mapping(uint256 => uint256[]) private _nftClaims;

    constructor(address _tokenAddress, address _nftAddress) public {
        require(
            _tokenAddress.isContract(),
            "_tokenAddress must be a contract address"
        );
        require(
            _nftAddress.isContract(),
            "_nftAddress must be a contract address"
        );
        tokenAddress = _tokenAddress;
        nftAddress = _nftAddress;
    }

    /**
     * Get Owner Claims
     *
     * @param owner - Claim Owner Address
     */
    function ownerClaims(address owner)
        external
        view
        returns (uint256[] memory)
    {
        require(owner != address(0), "Owner address cannot be 0");
        return _ownerClaims[owner];
    }

    /**
     * Get NFT Claims
     *
     * @param nftId - NFT ID
     */
    function nftClaims(uint256 nftId) external view returns (uint256[] memory) {
        require(nftId != 0, "nftId cannot be 0");
        return _nftClaims[nftId];
    }

    /**
     * Get Amount Claimed
     *
     * @param index - Claim Index
     */
    function claimed(uint256 index) external view returns (uint256) {
        return claims[index].amountClaimed;
    }

    /**
     * Get Total Claim Amount
     *
     * @param index - Claim Index
     */
    function totalAmount(uint256 index) external view returns (uint256) {
        return claims[index].totalAmount;
    }

    /**
     * Get Time Periods of Claim
     *
     * @param index - Claim Index
     */
    function timePeriods(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        return claims[index].timePeriods;
    }

    /**
     * Get Token Amounts of Claim
     *
     * @param index - Claim Index
     */
    function tokenAmounts(uint256 index)
        external
        view
        returns (uint256[] memory)
    {
        return claims[index].tokenAmounts;
    }

    /**
     * Create a Claim - To Vest Tokens to NFT
     *
     * @param _nftId - Tokens will be claimed by owner of _nftId
     * @param _startBlock - Block Number to start vesting from
     * @param _stopBlock - Block Number to end vesting at (Release all tokens)
     * @param _totalAmount - Total Amount to be Vested
     * @param _blockTime - Block Time (used for predicting _timePeriods)
     */
    function createClaim(
        uint256 _nftId,
        uint256 _startBlock,
        uint256 _stopBlock,
        uint256 _totalAmount,
        uint256 _blockTime
    ) external returns (bool) {
        require(_nftId != 0, "Cannot Vest to NFT 0");
        require(
            _stopBlock > _startBlock,
            "_stopBlock must be greater than _startBlock"
        );
        require(tokenAddress.isContract(), "Invalid tokenAddress");
        require(_totalAmount > 0, "Provide Token Amounts to Vest");
        require(
            ERC20(tokenAddress).allowance(msg.sender, address(this)) >=
                _totalAmount,
            "Provide token allowance to SuperNFTVestStream contract"
        );
        // Calculate estimated epoch for _startBlock
        StreamInfo memory streamInfo =
            StreamInfo(0, false, 0, 0, 0, new uint256[](0), new uint256[](0));
        (streamInfo.notOverflow, streamInfo.startDiff) = _startBlock.trySub(
            block.number
        );
        if (streamInfo.notOverflow) {
            // If Not Overflow
            streamInfo.startTime = block.timestamp.add(
                _blockTime.mul(streamInfo.startDiff)
            );
        } else {
            // If Overflow
            streamInfo.startDiff = block.number.sub(_startBlock);
            streamInfo.startTime = block.timestamp.sub(
                _blockTime.mul(streamInfo.startDiff)
            );
        }
        // Calculate _timePeriods & _tokenAmounts
        streamInfo.diff = _stopBlock.sub(_startBlock);
        streamInfo.amountPerBlock = _totalAmount.div(streamInfo.diff);
        streamInfo._timePeriods = new uint256[](streamInfo.diff);
        streamInfo._tokenAmounts = new uint256[](streamInfo.diff);

        streamInfo._timePeriods[0] = streamInfo.startTime;
        streamInfo._tokenAmounts[0] = streamInfo.amountPerBlock;
        for (uint256 i = 1; i < streamInfo.diff; i++) {
            streamInfo._timePeriods[i] = streamInfo._timePeriods[i - 1].add(
                _blockTime
            );
            streamInfo._tokenAmounts[i] = streamInfo.amountPerBlock;
        }
        // Transfer Tokens to SuperVestStream
        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            _totalAmount
        );
        // Create Claim
        Claim memory claim =
            Claim({
                owner: msg.sender,
                nftId: _nftId,
                timePeriods: streamInfo._timePeriods,
                tokenAmounts: streamInfo._tokenAmounts,
                totalAmount: _totalAmount,
                amountClaimed: 0,
                periodsClaimed: 0
            });
        claims.push(claim);
        uint256 index = claims.length - 1;
        // Map Claim Index to Owner & Beneficiary
        _ownerClaims[msg.sender].push(index);
        _nftClaims[_nftId].push(index);
        emit ClaimCreated(msg.sender, _nftId, _totalAmount, index);
        return true;
    }

    /**
     * Claim Tokens
     *
     * @param index - Index of the Claim
     */
    function claim(uint256 index) external {
        Claim storage claim = claims[index];
        // Check if msg.sender is the owner of the NFT
        require(
            msg.sender == ERC721(nftAddress).ownerOf(claim.nftId),
            "msg.sender must own the NFT"
        );
        // Check if anything is left to release
        require(
            claim.periodsClaimed < claim.timePeriods.length,
            "Nothing to release"
        );
        // Calculate releasable amount
        uint256 amount = 0;
        for (
            uint256 i = claim.periodsClaimed;
            i < claim.timePeriods.length;
            i++
        ) {
            if (claim.timePeriods[i] <= block.timestamp) {
                amount = amount.add(claim.tokenAmounts[i]);
                claim.periodsClaimed = claim.periodsClaimed.add(1);
            } else {
                break;
            }
        }
        // If there is any amount to release
        require(amount > 0, "Nothing to release");
        // Transfer Tokens from Owner to Beneficiary
        ERC20(tokenAddress).transfer(msg.sender, amount);
        claim.amountClaimed = claim.amountClaimed.add(amount);
        emit Claimed(claim.owner, claim.nftId, msg.sender, amount, index);
    }

    /**
     * Get Amount of tokens that can be claimed
     *
     * @param index - Index of the Claim
     */
    function claimableAmount(uint256 index) public view returns (uint256) {
        Claim storage claim = claims[index];
        // Calculate Claimable Amount
        uint256 amount = 0;
        for (
            uint256 i = claim.periodsClaimed;
            i < claim.timePeriods.length;
            i++
        ) {
            if (claim.timePeriods[i] <= block.timestamp) {
                amount = amount.add(claim.tokenAmounts[i]);
            } else {
                break;
            }
        }
        return amount;
    }
}