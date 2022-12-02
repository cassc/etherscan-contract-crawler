//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IZoo {
    function mint(address, uint256) external;
    function balanceOf(address who) external view returns (uint256);
}
interface IUSDT {
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint amount) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract ZooPrivateSale is AccessControl {
    address public owner;
    address public zoo;
    uint256 public fee = 8;
    uint256 public minLimit = 30 * 1e6;
    uint256 public maxLimit = 120 * 1e6;
    uint256 public totalSale = 0;
    bool saleEnabled = true;
//    uint256 public feeETH = 0.001 ether;
    address public usdt;
    mapping (address => bool) private whitelist;

    // roles
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    event ChangeFee(uint256 fee);

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), "not allowed");
        _;
    }

    constructor(
        address _zoo,
        address _usdt
    ) {
        owner = _msgSender();
        zoo = _zoo;
        usdt = _usdt;
        _grantRole(ADMIN, _msgSender());
    }

    /// @notice Mints Zoo
    /// @param _amount Quantity of NFTs to be minted
    /// @param _referral1 Address of the first referral
    /// @param _referral2 Address of the second referral
    function mintByUSDT(
        uint256 _amount,
        address _referral1,
        address _referral2
    ) external {
        require(saleEnabled, 'Private Sale Ended');
        require(_amount >= minLimit, 'Under Minimum Mint Limit');
        require(whitelist[_msgSender()] || IUSDT(zoo).balanceOf(_msgSender()) + _amount <= maxLimit, 'Above Max Limit');
        // check if the contract received fee
        require(IUSDT(usdt).allowance(_msgSender(), address(this)) >= fee * _amount, 'USDT Not approved');
        IUSDT(usdt).transferFrom(_msgSender(), owner, fee * _amount);
        IZoo(zoo).mint(_msgSender(), _amount);
        totalSale += _amount;
        if (_referral1 != address(0)) {
            IZoo(zoo).mint(_referral1, _amount / 10);
        }
        if (_referral2 != address(0)) {
            IZoo(zoo).mint(_referral2, _amount / 20);
        }
    }

    /// @notice Withdraw the accumulated ETH to address
    /// @param _to where the funds should be sent
    function withdraw(address payable _to) external {
        require(
            hasRole(ADMIN, msg.sender) || hasRole(WITHDRAWER_ROLE, msg.sender),
            "not allowed"
        );
        _to.transfer(address(this).balance);
        IUSDT(usdt).transfer(_to, IUSDT(usdt).balanceOf(address(this)));
    }

    function withdrawToMarketing(address _from, address _to, uint256 _amount) public onlyAdmin {
        require(IUSDT(usdt).allowance(_from, address(this)) >= _amount);
        IUSDT(usdt).transferFrom(_from, _to, _amount);
    }

    /// @notice Change minting fee
    function changeFee(uint256 _fee) external onlyAdmin {
        fee = _fee;
        emit ChangeFee(_fee);
    }

    function setWhitelist(address _user, bool _value) public onlyAdmin {
        whitelist[_user] = _value;
    }

    function checkMintable(address _user, uint256 _amount) view public returns (string memory) {
        if (whitelist[_user] == true && _amount >= minLimit) {
            return "Mintable";
        } else {
            if (_amount >= minLimit && IZoo(zoo).balanceOf(_user) + _amount <= maxLimit) {
                return "Mintable";
            } else {
                return "Not Mintable";
            }
        }
    }

    function getIsWhiteListed(address _user) view public returns(bool) {
        return whitelist[_user];
    }

    function setSaleEnabled(bool _value) public onlyAdmin {
        saleEnabled = _value;
    }

    function setParams(address _zoo, address _usdt, uint256 _fee, uint256 _minLimit, uint256 _maxLimit, uint256 _totalSale) public onlyAdmin {
        zoo = _zoo;
        usdt = _usdt;
        fee = _fee;
        minLimit = _minLimit;
        maxLimit = _maxLimit;
        totalSale = _totalSale;
    }

    /// @notice Grants the withdrawer role
    /// @param _role Role which needs to be assigned
    /// @param _user Address of the new withdrawer
    function grantRole(bytes32 _role, address _user) public override onlyAdmin {
        _grantRole(_role, _user);
    }

    /// @notice Revokes the withdrawer role
    /// @param _role Role which needs to be revoked
    /// @param _user Address which we want to revoke
    function revokeRole(bytes32 _role, address _user)
    public
    override
    onlyAdmin
    {
        _revokeRole(_role, _user);
    }
}