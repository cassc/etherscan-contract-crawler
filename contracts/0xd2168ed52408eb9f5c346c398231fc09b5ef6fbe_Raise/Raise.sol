/**
 *Submitted for verification at Etherscan.io on 2023-06-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

interface IRaiseNFT {
    function mint(address to, uint256 num) external;
}

contract Raise is Ownable {

    // Address => User
    mapping ( address => uint256 ) public donors;

    // List Of All Donors
    address[] private _allDonors;

    // Total Amount Donated
    uint256 private _totalDonated;

    // Receiver Of Donation
    address public raiseReceiver;

    // minimum contribution
    uint256 public min_contribution;

    // sale has ended
    bool public hasStarted;

    // Raise Token
    IERC20 public raiseToken;

    // Affiliate Structure
    struct Affiliate {
        address recipient;
        uint256 cut;
        address affiliateRecruiter;
        uint256 affiliateRecruiterCut;
    }

    // AffiliateID To Affiliate Receiver Address
    mapping ( uint256 => Affiliate ) public affiliates;

    // Amount brought in from affiliate program
    mapping ( address => uint256 ) public amountAffiliated;

    // devs that built raise page and contract
    address private dev;

    // dev cut
    uint256 private devCut;

    // raise NFT
    IRaiseNFT public NFT;

    // Donation Event, Trackers Donor And Amount Donated
    event Donated(address donor, uint256 amountDonated, uint256 totalInSale);

    constructor(
        address raiseToken_,
        address raiseReceiver_,
        address dev_,
        uint256 minContribution,
        uint256 devCut_
    ) {
        require(
            minContribution <= 1000, 'Min Contribution Too High'
        );
        raiseToken = IERC20(raiseToken_);
        raiseReceiver = raiseReceiver_;
        dev = dev_;
        devCut = devCut_;
        min_contribution = minContribution * 10**IERC20(raiseToken_).decimals();
    }

    function startSale() external onlyOwner {
        hasStarted = true;
    }

    function endSale() external onlyOwner {
        hasStarted = false;
    }

    function withdraw(IERC20 token_) external onlyOwner {
        token_.transfer(raiseReceiver, token_.balanceOf(address(this)));
    }

    function setMinContributions(uint min) external onlyOwner {
        min_contribution = min;
    }

    function setDevCut(uint newDevCut) external onlyOwner {
        devCut = newDevCut;
    }

    function setNFT(address NFT_) external onlyOwner {
        NFT = IRaiseNFT(NFT_);
    }

    function setAffiliateInfo(
        uint256 affiliateID,
        address recipient,
        uint256 cut,
        address affiliateRecruiter,
        uint256 affiliateRecruiterCut
    ) external onlyOwner {
        affiliates[affiliateID].recipient = recipient;
        affiliates[affiliateID].cut = cut;
        affiliates[affiliateID].affiliateRecruiter = affiliateRecruiter;
        affiliates[affiliateID].affiliateRecruiterCut = affiliateRecruiterCut;
    }

    function setBulkAffiliateInfo(
        uint256[] calldata affiliateID,
        address[] calldata recipient,
        uint256[] calldata cut,
        address[] calldata affiliateRecruiter,
        uint256[] calldata affiliateRecruiterCut
    ) external onlyOwner {
        uint len = affiliateID.length;
        for (uint i = 0; i < len;) {
            affiliates[affiliateID[i]].recipient = recipient[i];
            affiliates[affiliateID[i]].cut = cut[i];
            affiliates[affiliateID[i]].affiliateRecruiter = affiliateRecruiter[i];
            affiliates[affiliateID[i]].affiliateRecruiterCut = affiliateRecruiterCut[i];
            unchecked { ++i; }
        }
    }
    
    function setRaiseToken(address token) external onlyOwner {
        raiseToken = IERC20(token);
    }

    function setRaiseReceiver(address newReceiver) external onlyOwner {
        raiseReceiver = newReceiver;
    }

    function setDev(address newDev) external {
        require(msg.sender == dev, 'Only Dev');
        dev = newDev;
    }

    function donate(uint256 affiliateID, uint256 amount) external {
        uint received = _transferIn(amount, affiliateID);
        _process(msg.sender, received);
    }

    function mint(address user, uint256 amount) external {
        uint received = _transferIn(amount, 0);
        _process(user, received);
    }

    function donated(address user) external view returns(uint256) {
        return donors[user];
    }

    function allDonors() external view returns (address[] memory) {
        return _allDonors;
    }

    function allDonorsAndDonationAmounts() external view returns (address[] memory, uint256[] memory) {
        uint len = _allDonors.length;
        uint256[] memory amounts = new uint256[](len);
        for (uint i = 0; i < len;) {
            amounts[i] = donors[_allDonors[i]];
            unchecked { ++i; }
        }
        return (_allDonors, amounts);
    }

    function donorAtIndex(uint256 index) external view returns (address) {
        return _allDonors[index];
    }

    function numberOfDonors() external view returns (uint256) {
        return _allDonors.length;
    }

    function totalDonated() external view returns (uint256) {
        return _totalDonated;
    }

    function _process(address user, uint amount) internal {
        require(
            amount > 0,
            'Zero Amount'
        );
        require(
            hasStarted,
            'Sale Has Not Started'
        );

        // add to donor list if first donation
        if (donors[user] == 0) {
            _allDonors.push(user);
        }

        // increment amounts donated
        unchecked {
            donors[user] += amount;
            _totalDonated += amount;
        }

        // confirm donation exceeds minimum contribution
        require(
            donors[user] >= min_contribution,
            'Contribution too low'
        );

        // mint raise NFT to user
        if (address(NFT) != address(0)) {
            NFT.mint(user, 1);
        }

        // emit donation event
        emit Donated(user, amount, _totalDonated);
    }

    function _transferIn(uint amount, uint256 affiliateID) internal returns (uint256) {
        require(
            raiseToken.allowance(msg.sender, address(this)) >= amount,
            'Insufficient Allowance'
        );
        require(
            raiseToken.balanceOf(msg.sender) >= amount,
            'Insufficient Balance'
        );

        uint256 affiliateAmount;
        uint256 affiliateRecruiterAmount;

        if (affiliates[affiliateID].recipient != address(0)) {
            // there is an affiliate here

            // determine affiliate amount and recruiter amount, if any
            affiliateAmount = ( amount * affiliates[affiliateID].cut ) / 100;
            affiliateRecruiterAmount = ( amount * affiliates[affiliateID].affiliateRecruiterCut ) / 100;

            if (affiliateAmount > 0) {
                raiseToken.transferFrom(
                    msg.sender,
                    affiliates[affiliateID].recipient,
                    affiliateAmount
                );
                unchecked { 
                    amountAffiliated[affiliates[affiliateID].recipient] += amount;
                }
            }
            if (affiliateRecruiterAmount > 0) {
                address dest = affiliates[affiliateID].affiliateRecruiter == address(0) ? dev : affiliates[affiliateID].affiliateRecruiter;
                raiseToken.transferFrom(
                    msg.sender,
                    dest,
                    affiliateRecruiterAmount
                );
                unchecked { 
                    amountAffiliated[dest] += amount;
                }
            }

        }

        // transfer to dev
        uint256 devPercent = devCut - ( affiliates[affiliateID].cut + affiliates[affiliateID].affiliateRecruiterCut );
        uint256 devAmount = ( amount * devPercent ) / 100;
        if (devAmount > 0) {
            raiseToken.transferFrom(
                msg.sender,
                dev,
                devAmount
            );
        }

        // transfer rest to project
        uint256 remainder = amount - ( devAmount + affiliateAmount + affiliateRecruiterAmount );
        if (remainder > 0) {
            raiseToken.transferFrom(
                msg.sender,
                raiseReceiver,
                remainder
            );
        }
        return amount;
    }
}