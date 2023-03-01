// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./utils/SafeERC20.sol";
import "./utils/IERC20.sol";
import "./utils/Ownable.sol";
import "./utils/SafeMath.sol";
import "./Invite.sol";

contract DAPP is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable deadAddress =
    0x000000000000000000000000000000000000dEaD;

    address public invite;
    address public token;

    uint256 public rewardInviteRate;
    uint256[3] public inviteRates;
    uint256 public totalReward;

    mapping(address => uint256) public tokenBalance;
    mapping(address => bool) public tokenRole;

    struct Product {
        uint256 price;
        uint256 amount;
        uint256 cycle;
        uint256 tokenUse;
    }

    struct Order {
        address user;
        uint256 price;
        uint256 amount;
        uint256 startBlock;
        uint256 endBlock;
        uint256 lastRewardBlock;
        uint256 perBlockReward;
        uint256 rewardDebt;
    }


    Product[] public products;
    mapping(address => Order[]) public orders;

    constructor(address _invite, address _token) {
        token = _token;
        invite = _invite;
        rewardInviteRate = 500;
        inviteRates = [5000, 3000, 2000];
    }

    function setRate(uint256 _rewardInviteRate, uint256[3] memory _inviteRates) public onlyOwner {
        rewardInviteRate = _rewardInviteRate;
        inviteRates = _inviteRates;
    }

    function getProducts() external view returns (Product[] memory) {
        return products;
    }

    function getOrders(address _user) external view returns (Order[] memory) {
        return orders[_user];
    }

    function setAddresses(address _invite, address _token) public onlyOwner {
        invite = _invite;
        token = _token;
    }

    function addProduct(
        uint256 _price,
        uint256 _amount,
        uint256 _cycle,
        uint256 _tokenUse
    ) public onlyOwner {
        products.push(Product(_price, _amount, _cycle, _tokenUse));
    }

    function removeProduct(uint256 _pid) public onlyOwner {
        for (uint i = _pid; i < products.length - 1; i++) {
            products[i] = products[i + 1];
        }
        products.pop();
    }

    function updateProduct(
        uint256 _pid,
        uint256 _price,
        uint256 _amount,
        uint256 _cycle,
        uint256 _tokenUse
    ) public onlyOwner {
        products[_pid].price = _price;
        products[_pid].amount = _amount;
        products[_pid].cycle = _cycle;
        products[_pid].tokenUse = _tokenUse;
    }

    function getMultiplier(
        uint256 _from,
        uint256 _to,
        address _user,
        uint256 _oid
    ) public view returns (uint256) {
        Order storage order = orders[_user][_oid];
        if (_to <= order.endBlock) {
            return _to.sub(_from);
        } else if (_from >= order.endBlock) {
            return _to.sub(_from);
        } else {
            return
            order.endBlock.sub(_from).add(
                _to.sub(order.endBlock)
            );
        }
    }

    function pendingInfo(address _user, uint256 _oid)
    external
    view
    returns (uint256)
    {
        Order storage order = orders[_user][_oid];
        if (block.number > order.lastRewardBlock) {
            uint256 multiplier = getMultiplier(
                order.lastRewardBlock,
                block.number,
                _user,
                _oid
            );
            uint256 reward = multiplier.mul(order.perBlockReward);
            return reward;
        } else {
            return 0;
        }
    }

    function claim(uint256 _oid) external {
        address _user = _msgSender();
        Order storage order = orders[_user][_oid];
        uint256 multiplier = getMultiplier(
            order.lastRewardBlock,
            block.number,
            _user,
            _oid
        );
        uint256 reward = multiplier.mul(order.perBlockReward);
        order.rewardDebt = order.rewardDebt.add(reward);

        uint256[3] memory amounts = Invite(invite).getTradeInviteAmounts(reward, rewardInviteRate, inviteRates);
        address[] memory invites = Invite(invite).getParentsByLevel(_user, 3);
        address root = Invite(invite).rootAddress();

        for (uint256 i = 0; i < invites.length; i++) {
            if (invites[i] != address(0)) {
                IERC20(token).safeTransfer(invites[i], amounts[i]);
            } else {
                IERC20(token).safeTransfer(root, amounts[i]);
            }
            reward = reward.sub(amounts[i]);
        }

        totalReward = totalReward.add(reward);
        IERC20(token).safeTransfer(_user, reward);
        order.lastRewardBlock = block.number;
        if (block.number > order.endBlock) {
            removeOrder(_user, _oid);
        }
    }

    function removeOrder(address _user, uint256 _oid) private {
        for (uint i = _oid; i < orders[_user].length - 1; i++) {
            orders[_user][i] = orders[_user][i + 1];
        }
        orders[_user].pop();
    }

    function buyProduct(uint256 _pid, address _parent) external {

        if (_parent != address(0) && Invite(invite).getParent(_msgSender()) == address(0)) {
            Invite(invite).setParentBySettingRole(_msgSender(), _parent);
        }

        Product memory product = products[_pid];

        require(tokenBalance[_msgSender()] >= product.tokenUse, "not enough token");
        tokenBalance[_msgSender()] = tokenBalance[_msgSender()].sub(product.tokenUse);

        IERC20(token).safeTransferFrom(_msgSender(), address(this), product.price);
        IERC20(token).safeTransfer(deadAddress, product.price);

        Order memory order = Order(_msgSender(),
            product.price,
            product.amount,
            block.number,
            block.number.add(product.cycle),
            block.number,
            product.amount.div(product.cycle),
            0);

        orders[_msgSender()].push(order);
    }

    function setTokenRole(address _address, bool _role) external onlyOwner {
        tokenRole[_address] = _role;
    }

    function setTokenBalance(address _address, uint256 _amount) external {
        require(tokenRole[_msgSender()], "not allowed");
        tokenBalance[_address] = _amount;
    }

    function rescueToken(address tokenAddress, uint256 tokens)
    public
    onlyOwner
    returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function rescueBNB(address payable _recipient) public onlyOwner {
        _recipient.transfer(address(this).balance);
    }

}