// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library OcfiReferrals {
    struct Data {
        uint256 referralBonus;
        uint256 referredBonus;
        uint256 tokensNeededForRefferalNumber;
        mapping(uint256 => address) registeredReferrersByCode;
        mapping(address => uint256) registeredReferrersByAddress;
        uint256 currentRefferralCode;
    }

    uint256 private constant FACTOR_MAX = 10000;

    event RefferalCodeGenerated(address account, uint256 code, uint256 inc1, uint256 inc2);
    event UpdateReferralBonus(uint256 value);
    event UpdateReferredBonus(uint256 value);


    event UpdateTokensNeededForReferralNumber(uint256 value);


    function init(Data storage data) public {
        updateReferralBonus(data, 800); //2% bonus on buys from people you refer
        updateReferredBonus(data, 200); //2% bonus when you buy with referral code

        updateTokensNeededForReferralNumber(data, 100 * (10**18)); //100 tokens needed

        data.currentRefferralCode = 100;
    }

    function updateReferralBonus(Data storage data, uint256 value) public {
        require(value <= 1000, "invalid referral referredBonus"); //max 10%
        data.referralBonus = value;
        emit UpdateReferralBonus(value);
    }

    function updateReferredBonus(Data storage data, uint256 value) public {
        require(value <= 1000, "invalid referred bonus"); //max 10%
        data.referredBonus = value;
        emit UpdateReferredBonus(value);
    }

    function updateTokensNeededForReferralNumber(Data storage data, uint256 value) public {
        data.tokensNeededForRefferalNumber = value;
        emit UpdateTokensNeededForReferralNumber(value);
    }

    function random(Data storage data, uint256 min, uint256 max) private view returns (uint256) {
        return min + uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, data.currentRefferralCode))) % (max - min + 1);
    }

    function handleNewBalance(Data storage data, address account, uint256 balance) public {
        //already registered
        if(data.registeredReferrersByAddress[account] != 0) {
            return;
        }
        //not enough tokens
        if(balance < data.tokensNeededForRefferalNumber) {
            return;
        }
        //randomly increment referral code by anywhere from 5-50 so they
        //cannot be guessed easily
        uint256 inc1 = random(data, 5, 50);
        uint256 inc2 = random(data, 1, 9);
        data.currentRefferralCode += inc1;

        //don't allow referral code to end in 0,
        //so that ambiguous codes do not exist (ie, 420 and 4200)
        if(data.currentRefferralCode % 10 == 0) {
            data.currentRefferralCode += inc2;
        }

        data.registeredReferrersByCode[data.currentRefferralCode] = account;
        data.registeredReferrersByAddress[account] = data.currentRefferralCode;

        emit RefferalCodeGenerated(account, data.currentRefferralCode, inc1, inc2);
    }

    function getReferralCode(Data storage referrals, address account) public view returns (uint256) {
        return referrals.registeredReferrersByAddress[account];
    }

    function getReferrer(Data storage referrals, uint256 referralCode) public view returns (address) {
        return referrals.registeredReferrersByCode[referralCode];
    }

    function getReferralCodeFromTokenAmount(uint256 tokenAmount) private pure returns (uint256) {
        uint256 decimals = 18;

        uint256 numberAfterDecimals = tokenAmount % (10**decimals);

        uint256 checkDecimals = 3;

        while(checkDecimals < decimals) {
            uint256 factor = 10**(decimals - checkDecimals);
            //check if number is all 0s after the decimalth decimal,
            //ignoring anything in the last 6 because of Uniswap bug
            //where it adds a few non-zero digits at end
            uint256 mod = numberAfterDecimals % factor;

            if(mod < 10**6) {
                return (numberAfterDecimals - mod) / factor;
            }
            checkDecimals++;
        }

        return numberAfterDecimals;
    }

    function getReferrerFromTokenAmount(Data storage referrals, uint256 tokenAmount) public view returns (address) {
        uint256 referralCode = getReferralCodeFromTokenAmount(tokenAmount);

        return referrals.registeredReferrersByCode[referralCode];
    }

    function isValidReferrer(Data storage referrals, address referrer, uint256 referrerBalance, address transferTo) public view returns (bool) {
        if(referrer == address(0)) {
            return false;
        }

        uint256 tokensNeeded = referrals.tokensNeededForRefferalNumber;

        return referrerBalance >= tokensNeeded && referrer != transferTo;
    }
}