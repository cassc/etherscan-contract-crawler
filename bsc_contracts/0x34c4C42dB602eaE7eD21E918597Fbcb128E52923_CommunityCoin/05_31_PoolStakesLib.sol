// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/ICommunityCoin.sol";
import "../interfaces/ICommunityStakingPoolFactory.sol";
import "../interfaces/ICommunityStakingPool.sol";
import "../interfaces/IRewards.sol";

//import "hardhat/console.sol";
library PoolStakesLib {
    using MinimumsLib for MinimumsLib.UserStruct;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    function unstakeablePart(
        mapping(address => ICommunityCoin.UserData) storage users,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances,
        address from, 
        address to, 
        IStructs.Total storage total, 
        uint256 amount
    ) external {
        // console.log("amount                         =",amount);
        // console.log("remainingAmount                =",remainingAmount);
        // console.log("users[from].unstakeable        =",users[from].unstakeable);
        // console.log("users[from].unstakeableBonuses =",users[from].unstakeableBonuses);
        // console.log("users[to].unstakeable          =",users[to].unstakeable);
        // console.log("users[to].unstakeableBonuses   =",users[to].unstakeableBonuses);
        // else it's just transfer

        // so while transfer user will user free tokens at first
        // then try to use locked. when using locked we should descrease

        //users[from].unstakeableBonuses;
        //try to get from bonuses
        //  here just increase redeemable
        //then try to get from main unstakeable
        //  here decrease any unstakeable vars
        //              increase redeemable
        uint256 r;
        uint256 left = amount;
        if (users[from].unstakeableBonuses > 0) {
            
            if (users[from].unstakeableBonuses >= left) {
                r = left;
            } else {
                r = users[from].unstakeableBonuses;
            }

            if (to == address(0)) {
                // it's simple burn and tokens can not be redeemable
            } else {
                total.totalRedeemable += r;
            }

            PoolStakesLib._removeBonusThroughInstances(users, _instances, from, r);
            users[from].unstakeableBonuses -= r;
            left -= r;
        }

        if ((left > 0) && (users[from].unstakeable >= left)) {
            // console.log("#2");
            if (users[from].unstakeable >= left) {
                r = left;
            } else {
                r = users[from].unstakeable;
            }

            //   r = users[from].unstakeable - left;
            // if (totalUnstakeable >= r) {
            users[from].unstakeable -= r;
            total.totalUnstakeable -= r;

            if (to == address(0)) {
                // it's simple burn and tokens can not be redeemable
            } else {
                total.totalRedeemable += r;
            }

            PoolStakesLib._removeMainThroughInstances(users, _instances, from, r);

            //left -= r;

            // }
        }

        // if (users[from].unstakeable >= remainingAmount) {
        //     uint256 r = users[from].unstakeable - remainingAmount;
        //     // if (totalUnstakeable >= r) {
        //     users[from].unstakeable -= r;
        //     totalUnstakeable -= r;
        //     if (to == address(0)) {
        //         // it's simple burn and tokens can not be redeemable
        //     } else {
        //         totalRedeemable += r;
        //     }
        //     // }
        // }
        // console.log("----------------------------");
        // console.log("users[from].unstakeable        =",users[from].unstakeable);
        // console.log("users[from].unstakeableBonuses =",users[from].unstakeableBonuses);
        // console.log("users[to].unstakeable          =",users[to].unstakeable);
        // console.log("users[to].unstakeableBonuses   =",users[to].unstakeableBonuses);
    }

    
    function _removeMainThroughInstances(
        mapping(address => ICommunityCoin.UserData) storage users,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances,
        address account, 
        uint256 amount
    ) internal {
        uint256 len = users[account].instancesList.length();
        address[] memory instances2Delete = new address[](len);
        uint256 j = 0;
        address instance;
        for (uint256 i = 0; i < len; i++) {
            instance = users[account].instancesList.at(i);
            if (_instances[instance].unstakeable[account] >= amount) {
                _instances[instance].unstakeable[account] -= amount;
                _instances[instance].redeemable += amount;
            } else if (_instances[instance].unstakeable[account] > 0) {
                _instances[instance].unstakeable[account] = 0;
                instances2Delete[j] = instance;
                j += 1;
                amount -= _instances[instance].unstakeable[account];
            }
        }

        // do deletion out of loop above. because catch out of array
        cleanInstancesList(users, _instances, account, instances2Delete, j);
    }

    function _removeBonusThroughInstances(
        mapping(address => ICommunityCoin.UserData) storage users,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances,
        // address account, 
        // // address to, 
        // // IStructs.Total storage total, 
        // uint256 amount
        address account, 
        uint256 amount
    ) internal {
        //console.log("START::_removeBonusThroughInstances");
        uint256 len = users[account].instancesList.length();
        address[] memory instances2Delete = new address[](len);
        uint256 j = 0;
        //console.log("_removeBonusThroughInstances::len", len);
        address instance;
        for (uint256 i = 0; i < len; i++) {
            instance = users[account].instancesList.at(i);
            if (_instances[instance].unstakeableBonuses[account] >= amount) {
                //console.log("_removeBonusThroughInstances::#1");
                _instances[instance].unstakeableBonuses[account] -= amount;
            } else if (_instances[instance].unstakeableBonuses[account] > 0) {
                //console.log("_removeBonusThroughInstances::#2");
                _instances[instance].unstakeableBonuses[account] = 0;
                instances2Delete[i] = instance;
                j += 1;
                amount -= _instances[instance].unstakeableBonuses[account];
            }
        }

        // do deletion out of loop above. because catch out of array
        PoolStakesLib.cleanInstancesList(users, _instances, account, instances2Delete, j);
        //console.log("END::_removeBonusThroughInstances");
    }

    /*
    function _removeBonus(
        address instance,
        address account,
        uint256 amount
    ) internal {
        // todo 0:
        //  check `instance` exists in list.
        //  check `amount` should be less or equal `_instances[instance].unstakeableBonuses[account]`

        _instances[instance].unstakeableBonuses[account] -= amount;
        users[account].unstakeableBonuses -= amount;

        if (_instances[instance].unstakeable[account] >= amount) {
            _instances[instance].unstakeable[account] -= amount;
        } else if (_instances[instance].unstakeable[account] > 0) {
            _instances[instance].unstakeable[account] = 0;
            //amount -= _instances[instance].unstakeable[account];
        }
        _cleanInstance(account, instance);
    }
    */

    function cleanInstancesList(
        
        mapping(address => ICommunityCoin.UserData) storage users,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances,
        address account,
        address[] memory instances2Delete,
        uint256 indexUntil
    ) internal {
        // console.log("start::cleanInstancesList");
        // console.log("cleanInstancesList::indexUntil=",indexUntil);
        //uint256 len = instances2Delete.length;
        if (indexUntil > 0) {
            for (uint256 i = 0; i < indexUntil; i++) {
                PoolStakesLib._cleanInstance(users, _instances, account, instances2Delete[i]);
            }
        }
        // console.log("end::cleanInstancesList");
    }

     function _cleanInstance(
        mapping(address => ICommunityCoin.UserData) storage users,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances,
        address account, 
        address instance
    ) internal {
        //console.log("start::_cleanInstance");
        if (_instances[instance].unstakeableBonuses[account] == 0 && _instances[instance].unstakeable[account] == 0) {
            users[account].instancesList.remove(instance);
        }

        // console.log("end::_cleanInstance");
    }

    function lockedPart(
        mapping(address => ICommunityCoin.UserData) storage users,
        address from, 
        uint256 remainingAmount
    ) external {
        /*
        balance = 100
        amount = 40
        locked = 50
        minimumsTransfer - ? =  0
        */
        /*
        balance = 100
        amount = 60
        locked = 50
        minimumsTransfer - ? = [50 > (100-60)] locked-(balance-amount) = 50-(40)=10  
        */
        /*
        balance = 100
        amount = 100
        locked = 100
        minimumsTransfer - ? = [100 > (100-100)] 100-(100-100)=100  
        */

        uint256 locked = users[from].tokensLocked._getMinimum();
        uint256 lockedBonus = users[from].tokensBonus._getMinimum();
        //else drop locked minimum, but remove minimums even if remaining was enough
        //minimumsTransfer(account, ZERO_ADDRESS, (locked - remainingAmount))
        // console.log("locked---start");
        // console.log("balance        = ",balance);
        // console.log("amount         = ",amount);
        // console.log("remainingAmount= ",remainingAmount);
        // console.log("locked         = ",locked);
        // console.log("lockedBonus    = ",lockedBonus);
        if (locked + lockedBonus > 0 && locked + lockedBonus >= remainingAmount) {
            // console.log("#1");
            uint256 locked2Transfer = locked + lockedBonus - remainingAmount;
            if (lockedBonus >= locked2Transfer) {
                // console.log("#2.1");
                users[from].tokensBonus.minimumsTransfer(
                    users[address(0)].tokensBonus,
                    true,
                    (lockedBonus - locked2Transfer)
                );
            } else {
                // console.log("#2.2");

                // console.log("locked2Transfer = ", locked2Transfer);
                //uint256 left = (remainingAmount - lockedBonus);
                if (lockedBonus > 0) {
                    users[from].tokensBonus.minimumsTransfer(
                        users[address(0)].tokensBonus,
                        true,
                        lockedBonus
                    );
                    locked2Transfer -= lockedBonus;
                }
                users[from].tokensLocked.minimumsTransfer(
                    users[address(0)].tokensLocked,
                    true,
                    locked2Transfer
                );
            }
        }
        // console.log("locked         = ",locked);
        // console.log("lockedBonus    = ",lockedBonus);
        // console.log("locked---end");
        //-------------------
    }

    function proceedPool(
        ICommunityStakingPoolFactory instanceManagment,
        address hook,
        address account,
        address pool,
        uint256 amount,
        ICommunityCoin.Strategy strategy /*, string memory errmsg*/
    ) external {

        ICommunityStakingPoolFactory.InstanceInfo memory instanceInfo = instanceManagment.getInstanceInfoByPoolAddress(pool);

        try ICommunityStakingPool(pool).redeem(account, amount) returns (
            uint256 affectedAmount,
            uint64 rewardsRateFraction
        ) {
// console.log("proceedPool");
// console.log(account, amount);
            if (
                (hook != address(0)) &&
                (strategy == ICommunityCoin.Strategy.UNSTAKE)
            ) {
                require(instanceInfo.exists == true);
                IRewards(hook).onUnstake(pool, account, instanceInfo.duration, affectedAmount, rewardsRateFraction);
            }
        } catch {
            if (strategy == ICommunityCoin.Strategy.UNSTAKE) {
                revert ICommunityCoin.UNSTAKE_ERROR();
            } else if (strategy == ICommunityCoin.Strategy.REDEEM) {
                revert ICommunityCoin.REDEEM_ERROR();
            }
            
        }
        
    }

    // adjusting amount and applying some discounts, fee, etc
    function getAmountLeft(
        address account,
        uint256 amount,
        uint256 totalSupplyBefore,
        ICommunityCoin.Strategy strategy,
        IStructs.Total storage total,
        // uint256 totalRedeemable,
        // uint256 totalUnstakeable,
        // uint256 totalReserves,
        uint256 discountSensitivity,
        mapping(address => ICommunityCoin.UserData) storage users,
        uint64 unstakeTariff, 
        uint64 redeemTariff,
        uint64 fraction

    ) external view returns(uint256) {
        
        if (strategy == ICommunityCoin.Strategy.REDEEM) {

            // LPTokens =  WalletTokens * ratio;
            // ratio = A / (A + B * discountSensitivity);
            // где 
            // discountSensitivity - constant set in constructor
            // A = totalRedeemable across all pools
            // B = totalSupply - A - totalUnstakeable
            uint256 A = total.totalRedeemable;
            uint256 B = totalSupplyBefore - A - total.totalUnstakeable;
            // uint256 ratio = A / (A + B * discountSensitivity);
            // amountLeft =  amount * ratio; // LPTokens =  WalletTokens * ratio;

            // --- proposal from audit to keep precision after division
            // amountLeft = amount * A / (A + B * discountSensitivity / 100000);
            amount = amount * A * fraction;
            amount = amount / (A + B * discountSensitivity / fraction);
            amount = amount / fraction;

            /////////////////////////////////////////////////////////////////////
            // Formula: #1
            // discount = mainTokens / (mainTokens + bonusTokens);
            // 
            // but what we have: 
            // - mainTokens     - tokens that user obtain after staked 
            // - bonusTokens    - any bonus tokens. 
            //   increase when:
            //   -- stakers was invited via community. so inviter will obtain amount * invitedByFraction
            //   -- calling addToCirculation
            //   decrease when:
            //   -- by applied tariff when redeem or unstake
            // so discount can be more then zero
            // We didn't create int256 bonusTokens variable. instead this we just use totalSupply() == (mainTokens + bonusTokens)
            // and provide uint256 totalReserves as tokens amount  without bonuses.
            // increasing than user stakes and decreasing when redeem
            // smth like this
            // discount = totalReserves / (totalSupply();
            // !!! keep in mind that we have burn tokens before it's operation and totalSupply() can be zero. use totalSupplyBefore instead 

            amount = amount * total.totalReserves / totalSupplyBefore;

            /////////////////////////////////////////////////////////////////////

            // apply redeem tariff                    
            amount -= amount * redeemTariff/fraction;
            
        }

        if (strategy == ICommunityCoin.Strategy.UNSTAKE) {

            if (
               (totalSupplyBefore - users[account].tokensBonus._getMinimum() < amount) || // insufficient amount
               (users[account].unstakeable < amount)  // check if user can unstake such amount across all instances
            ) {
                revert ICommunityCoin.InsufficientAmount(account, amount);
            }

            // apply unstake tariff
            amount -= amount * unstakeTariff/fraction;


        }

        return amount;
        
    }
    
    // create map of instance->amount or LP tokens that need to redeem
    function available(
        address account,
        uint256 amount,
        address[] memory preferredInstances,
        ICommunityCoin.Strategy strategy,
        ICommunityStakingPoolFactory instanceManagment,
        mapping(address => ICommunityCoin.InstanceStruct) storage _instances
    ) 
        external 
        view
        returns(
            address[] memory instancesAddress,  // instance's addresses
            uint256[] memory values,            // amounts to redeem in instance
            uint256[] memory amounts,           // itrc amount equivalent(applied num/den)
            uint256 len
        ) 
    {
    
        //  uint256 FRACTION = 100000;

        if (preferredInstances.length == 0) {
            preferredInstances = instanceManagment.instances();
        }

        instancesAddress = new address[](preferredInstances.length);
        values = new uint256[](preferredInstances.length);
        amounts = new uint256[](preferredInstances.length);

        uint256 amountLeft = amount;
        

        len = 0;
        uint256 amountToRedeem;

        // now calculate from which instances we should reduce tokens
        for (uint256 i = 0; i < preferredInstances.length; i++) {

            if (
                (strategy == ICommunityCoin.Strategy.UNSTAKE) &&
                (_instances[preferredInstances[i]].unstakeable[account] > 0)
            ) {
                amountToRedeem = 
                    amountLeft > _instances[preferredInstances[i]].unstakeable[account]
                    ?
                    _instances[preferredInstances[i]].unstakeable[account]
                        // _instances[preferredInstances[i]]._instanceStaked > users[account].unstakeable
                        // ? 
                        // users[account].unstakeable
                        // :
                        // _instances[preferredInstances[i]]._instanceStaked    
                    :
                    amountLeft;

            }  
            if (
                strategy == ICommunityCoin.Strategy.REDEEM
            ) {
                amountToRedeem = 
                    amountLeft > _instances[preferredInstances[i]]._instanceStaked
                    ? 
                    _instances[preferredInstances[i]]._instanceStaked
                    : 
                    amountLeft
                    ;
            }
                
            if (amountToRedeem > 0) {

                ICommunityStakingPoolFactory.InstanceInfo memory instanceInfo;
                instancesAddress[len] = preferredInstances[i]; 
                instanceInfo =  instanceManagment.getInstanceInfoByPoolAddress(preferredInstances[i]); // todo is exist there?
                amounts[len] = amountToRedeem;
                //backward conversion( СС -> LP)
                values[len] = amountToRedeem * (instanceInfo.denominator) / (instanceInfo.numerator);
                
                len += 1;
                
                amountLeft -= amountToRedeem;
            }
        }
        
        if(amountLeft > 0) {revert ICommunityCoin.InsufficientAmount(account, amount);}

    }
}