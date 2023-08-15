// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {UnauthorizedToExchangeRoyaltyTokenToETH} from "contracts/interface/D4AErrors.sol";

import "../D4ASettings/D4ASettingsBaseStorage.sol";
import "../feepool/D4AFeePool.sol";
import {IProtoDAOSettingsReadable} from "../ProtoDAOSettings/IProtoDAOSettingsReadable.sol";
import {ProtoDAOSettingsBaseStorage} from "../ProtoDAOSettings/ProtoDAOSettingsBaseStorage.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ID4AMintableERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

library D4AReward {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct reward_info {
        uint256[] active_rounds;
        uint256 to_issue_round_index;
        uint256 final_issued_round_index;
        uint256 project_owner_to_claim_round_index;
        uint256 issued_rounds;
        mapping(uint256 => uint256) round_2_total_amount;
        mapping(bytes32 => uint256) canvas_2_to_claim_round_index;
        mapping(bytes32 => mapping(uint256 => uint256)) canvas_2_block_2_amount;
        mapping(bytes32 => uint256) canvas_2_unclaimed_amount;
        mapping(address => uint256) minter_2_to_claim_round_index;
        mapping(address => mapping(uint256 => uint256)) minter_2_block_2_amount;
        mapping(address => uint256) minter_2_unclaimed_amount;
    }

    function issueTokenToCurrentRound(
        mapping(bytes32 => reward_info) storage _allRewards,
        bytes32 _project_id,
        address erc20_token,
        uint256 _start_round,
        uint256 total_rounds,
        uint256 erc20_total_supply
    ) public returns (uint256) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        ID4ADrb drb = l.drb;
        uint256 cur_round = drb.currentRound();
        if (cur_round <= _start_round) {
            return 0;
        }
        reward_info storage ri = _allRewards[_project_id];

        uint256 n = ri.issued_rounds;
        if (n >= total_rounds) {
            return 0;
        }
        {
            uint256 i = 0;
            for (i = ri.to_issue_round_index; i < ri.active_rounds.length; i++) {
                if (ri.active_rounds[i] == cur_round) {
                    break;
                }
                if (_allRewards[_project_id].round_2_total_amount[ri.active_rounds[i]] != 0) {
                    n = n + 1;
                    _allRewards[_project_id].final_issued_round_index = i;
                    _allRewards[_project_id].to_issue_round_index = i + 1;
                    if (n == total_rounds) {
                        break;
                    }
                }
            }
        }

        uint256 amount = (n - _allRewards[_project_id].issued_rounds) * erc20_total_supply / total_rounds;

        if (amount > 0) ID4AMintableERC20(erc20_token).mint(address(this), amount);
        _allRewards[_project_id].issued_rounds = n;
        return amount;
    }

    function updateMintWithAmount(
        mapping(bytes32 => reward_info) storage _allRewards,
        bytes32 _project_id,
        bytes32 _canvas_id,
        uint256 canvasFee,
        uint256 daoFee,
        uint256 total_rounds,
        mapping(bytes32 => mapping(uint256 => uint256)) storage round_2_total_eth
    ) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        ID4ADrb drb = l.drb;
        uint256 cur_round = drb.currentRound();

        reward_info storage ri = _allRewards[_project_id];
        if (ri.active_rounds.length != 0 && ri.active_rounds[ri.active_rounds.length - 1] != cur_round) {
            require(ri.active_rounds.length < total_rounds, "rounds end, cannot mint");
        }

        uint256 canvasCreatroERC20Ratio =
            IProtoDAOSettingsReadable(address(this)).getCanvasCreatorERC20Ratio(_project_id);
        uint256 nftMinterERC20Ratio = IProtoDAOSettingsReadable(address(this)).getNftMinterERC20Ratio(_project_id);
        ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[_project_id];
        if (di.newDAO) {
            ri.round_2_total_amount[cur_round] += daoFee;
            ri.canvas_2_block_2_amount[_canvas_id][cur_round] += daoFee * canvasCreatroERC20Ratio;
            ri.minter_2_block_2_amount[msg.sender][cur_round] += daoFee * nftMinterERC20Ratio;
            round_2_total_eth[_project_id][cur_round] += daoFee;
        } else {
            ri.round_2_total_amount[cur_round] += canvasFee;
            ri.canvas_2_block_2_amount[_canvas_id][cur_round] += canvasFee;
            round_2_total_eth[_project_id][cur_round] += daoFee;
        }

        if (ri.active_rounds.length == 0) {
            ri.active_rounds.push(cur_round);
        } else {
            if (ri.active_rounds[ri.active_rounds.length - 1] != cur_round) {
                ri.active_rounds.push(cur_round);
            }
        }
    }

    function claimCanvasReward(
        mapping(bytes32 => reward_info) storage _allRewards,
        bytes32 _project_id,
        bytes32 _canvas_id,
        address _erc20_token,
        uint256 _start_round,
        uint256 _total_rounds,
        uint256 erc20_total_supply
    ) public returns (uint256) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        updateRewardForCanvas(_allRewards, _project_id, _canvas_id, _start_round, _total_rounds, erc20_total_supply);
        reward_info storage ri = _allRewards[_project_id];
        uint256 total_amount = ri.canvas_2_unclaimed_amount[_canvas_id];
        ri.canvas_2_unclaimed_amount[_canvas_id] = 0;

        if (total_amount > 0) {
            address canvas_owner = l.owner_proxy.ownerOf(_canvas_id);
            IERC20Upgradeable(_erc20_token).safeTransfer(canvas_owner, total_amount);
        }
        return total_amount;
    }

    function claimNftMinterReward(
        mapping(bytes32 => reward_info) storage _allRewards,
        bytes32 daoId,
        address minter,
        address erc20Token,
        uint256 startRound,
        uint256 totalRounds,
        uint256 erc20TotalSupply
    ) public returns (uint256) {
        updateRewardForMinter(_allRewards, daoId, minter, startRound, totalRounds, erc20TotalSupply);
        reward_info storage ri = _allRewards[daoId];
        uint256 totalAmount = ri.minter_2_unclaimed_amount[minter];
        ri.minter_2_unclaimed_amount[minter] = 0;

        if (totalAmount > 0) IERC20Upgradeable(erc20Token).safeTransfer(minter, totalAmount);

        return totalAmount;
    }

    function claimNftMinterRewardWithETH(
        bytes32 _project_id,
        address erc20_token,
        uint256 erc20_amount,
        address _fee_pool,
        mapping(bytes32 => mapping(uint256 => uint256)) storage round_2_total_eth,
        address minter
    ) public returns (uint256) {
        if (erc20_amount == 0) return 0;
        if (msg.sender != minter) revert UnauthorizedToExchangeRoyaltyTokenToETH();
        uint256 to_send = sendETH(erc20_token, _fee_pool, _project_id, minter, minter, erc20_amount, round_2_total_eth);
        return to_send;
    }

    function updateRewardForCanvas(
        mapping(bytes32 => reward_info) storage _allRewards,
        bytes32 _project_id,
        bytes32 _canvas_id,
        uint256 _start_round,
        uint256 _total_rounds,
        uint256 erc20_total_supply
    ) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        uint256 cur_round;
        {
            ID4ADrb drb = l.drb;
            cur_round = drb.currentRound();
        }

        if (cur_round == _start_round) {
            return;
        }

        {
            reward_info storage ri = _allRewards[_project_id];
            if (ri.active_rounds.length == 0) {
                return;
            }
            if (ri.active_rounds.length <= ri.canvas_2_to_claim_round_index[_canvas_id]) {
                return;
            }

            uint256 numerator = erc20_total_supply;
            uint256 denominator = l.ratio_base * _total_rounds;

            uint256 canvasAmount;
            for (uint256 i = ri.canvas_2_to_claim_round_index[_canvas_id]; i <= ri.final_issued_round_index; i++) {
                if (ri.active_rounds[i] == cur_round) {
                    break;
                }
                canvasAmount += numerator * ri.canvas_2_block_2_amount[_canvas_id][ri.active_rounds[i]]
                    / ri.round_2_total_amount[ri.active_rounds[i]]; //  (1ETH * 30% + 2ETH * 20%) / (1ETH + 2ETH)
                ri.canvas_2_to_claim_round_index[_canvas_id] = i + 1;
            }

            ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[_project_id];
            bool isNewDao = di.newDAO;
            if (isNewDao) {
                ri.canvas_2_unclaimed_amount[_canvas_id] += canvasAmount / denominator;
            } else {
                ri.canvas_2_unclaimed_amount[_canvas_id] += canvasAmount * l.canvas_erc20_ratio / denominator;
            }
        }
    }

    function updateRewardForMinter(
        mapping(bytes32 => reward_info) storage _allRewards,
        bytes32 _project_id,
        address minter,
        uint256 _start_round,
        uint256 _total_rounds,
        uint256 erc20_total_supply
    ) public {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        uint256 cur_round;
        {
            ID4ADrb drb = l.drb;
            cur_round = drb.currentRound();
        }

        if (cur_round == _start_round) {
            return;
        }

        {
            reward_info storage ri = _allRewards[_project_id];
            if (ri.active_rounds.length == 0) {
                return;
            }
            if (ri.active_rounds.length <= ri.minter_2_to_claim_round_index[minter]) {
                return;
            }

            uint256 numerator = erc20_total_supply;
            uint256 denominator = l.ratio_base * _total_rounds;

            uint256 minterAmount;
            for (uint256 i = ri.minter_2_to_claim_round_index[minter]; i <= ri.final_issued_round_index; i++) {
                if (ri.active_rounds[i] == cur_round) {
                    break;
                }
                minterAmount += numerator * ri.minter_2_block_2_amount[minter][ri.active_rounds[i]]
                    / ri.round_2_total_amount[ri.active_rounds[i]]; //  (1ETH * 65% + 2ETH * 75%) / (1ETH + 2ETH)
                ri.minter_2_to_claim_round_index[minter] = i + 1;
            }

            ProtoDAOSettingsBaseStorage.DaoInfo storage di = ProtoDAOSettingsBaseStorage.layout().allDaos[_project_id];
            bool isNewDao = di.newDAO;
            if (isNewDao) {
                ri.minter_2_unclaimed_amount[minter] += minterAmount / denominator;
            }
        }
    }

    function claimCanvasRewardWithETH(
        bytes32 _project_id,
        bytes32 _canvas_id,
        address erc20_token,
        uint256 erc20_amount,
        address _fee_pool,
        mapping(bytes32 => mapping(uint256 => uint256)) storage round_2_total_eth
    ) public returns (uint256) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (erc20_amount == 0) return 0;
        address _owner = l.owner_proxy.ownerOf(_canvas_id);
        if (msg.sender != _owner) revert UnauthorizedToExchangeRoyaltyTokenToETH();
        uint256 to_send = sendETH(erc20_token, _fee_pool, _project_id, _owner, _owner, erc20_amount, round_2_total_eth);
        return to_send;
    }

    function claimProjectReward(
        mapping(bytes32 => reward_info) storage _allRewards,
        bytes32 _project_id,
        address erc20_token,
        uint256 _start_round,
        uint256 _total_rounds,
        uint256 erc20_total_supply
    ) public returns (uint256) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        reward_info storage ri = _allRewards[_project_id];
        if (ri.active_rounds.length == 0) {
            return 0;
        }
        if (ri.active_rounds.length <= ri.project_owner_to_claim_round_index) {
            return 0;
        }

        uint256 from = ri.active_rounds[ri.project_owner_to_claim_round_index];
        if (from == 0) {
            from = _start_round;
        }
        ID4ADrb drb = l.drb;
        uint256 cur_round = drb.currentRound();
        if (from == cur_round) {
            return 0;
        }

        uint256 n = ri.final_issued_round_index + 1 - ri.project_owner_to_claim_round_index;
        ri.project_owner_to_claim_round_index = ri.final_issued_round_index + 1;

        {
            uint256 d4a_amount = erc20_total_supply * l.d4a_erc20_ratio * n / (l.ratio_base * _total_rounds);
            if (d4a_amount != 0) {
                IERC20Upgradeable(erc20_token).safeTransfer(l.protocol_fee_pool, d4a_amount);
            }
        }
        uint256 project_amount = erc20_total_supply * l.project_erc20_ratio * n / (l.ratio_base * _total_rounds);

        if (project_amount != 0) {
            address project_owner = l.owner_proxy.ownerOf(_project_id);
            IERC20Upgradeable(erc20_token).safeTransfer(project_owner, project_amount);
        }
        return project_amount;
    }

    event D4AExchangeERC20ToETH(
        bytes32 project_id, address owner, address to, uint256 erc20_amount, uint256 eth_amount
    );

    function claimProjectERC20RewardWithETH(
        bytes32 _project_id,
        address erc20_token,
        uint256 erc20_amount,
        address _fee_pool,
        mapping(bytes32 => mapping(uint256 => uint256)) storage round_2_total_eth
    ) public returns (uint256) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        if (erc20_amount == 0) return 0;
        address _owner = l.owner_proxy.ownerOf(_project_id);
        if (msg.sender != _owner) revert UnauthorizedToExchangeRoyaltyTokenToETH();
        uint256 to_send = sendETH(erc20_token, _fee_pool, _project_id, _owner, _owner, erc20_amount, round_2_total_eth);
        return to_send;
    }

    function sendETH(
        address erc20_token,
        address fee_pool,
        bytes32 project_id,
        address _owner,
        address _to,
        uint256 erc20_amount,
        mapping(bytes32 => mapping(uint256 => uint256)) storage round_2_total_eth
    ) public returns (uint256) {
        D4ASettingsBaseStorage.Layout storage l = D4ASettingsBaseStorage.layout();
        ID4AMintableERC20(erc20_token).burn(_owner, erc20_amount);
        ID4AMintableERC20(erc20_token).mint(fee_pool, erc20_amount);

        ID4ADrb drb = l.drb;
        uint256 cur_round = drb.currentRound();

        // TODO: create a getter to fetch the latest ERC20/ETH price
        uint256 circulate_erc20 = IERC20Upgradeable(erc20_token).totalSupply() + erc20_amount
            - IERC20Upgradeable(erc20_token).balanceOf(fee_pool);
        if (circulate_erc20 == 0) return 0;
        uint256 avaliable_eth = fee_pool.balance - round_2_total_eth[project_id][cur_round];
        uint256 to_send = erc20_amount * avaliable_eth / circulate_erc20;
        if (to_send != 0) {
            D4AFeePool(payable(fee_pool)).transfer(address(0x0), payable(_to), to_send);
        }
        emit D4AExchangeERC20ToETH(project_id, _owner, _to, erc20_amount, to_send);
        return to_send;
    }

    function ToETH(
        address erc20_token,
        address fee_pool,
        bytes32 project_id,
        address _owner,
        address _to,
        uint256 amount,
        mapping(bytes32 => mapping(uint256 => uint256)) storage round_2_total_eth
    ) public returns (uint256) {
        return sendETH(erc20_token, fee_pool, project_id, _owner, _to, amount, round_2_total_eth);
    }
}