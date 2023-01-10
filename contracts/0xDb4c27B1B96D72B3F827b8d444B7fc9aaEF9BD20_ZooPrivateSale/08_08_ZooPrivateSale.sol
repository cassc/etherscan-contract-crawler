//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IZoo {
    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}

interface IUSDT {
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint amount) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract ZooPrivateSale is AccessControl {
    address public zoo;
    uint256 public fee = 85;
    uint256 public minLimit = 250 * 1e6;
    uint256 public maxLimit = 1250 * 1e6;
    uint256 public totalSale = 0;
    bool saleEnabled = true;
    address public usdt;
    address public owner;
    mapping(address => bool) private whitelist;

    // roles
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    event SetParams(uint256 fee, address zoo, address usdt);
    event ZooBought(uint256 indexed zooAmount, address indexed buyer);

    modifier onlyAdmin() {
        require(hasRole(ADMIN, _msgSender()), "not allowed");
        _;
    }

    constructor(address _zoo, address _usdt) {
        zoo = _zoo;
        usdt = _usdt;
        owner = _msgSender();
        _grantRole(ADMIN, _msgSender());
    }

    /// @notice Exchanges Zoo for USDT
    /// @param _amount Quantity of ZOO to buy
    function buyWithUSDT(uint256 _amount) external {
        require(
            IZoo(zoo).balanceOf(address(this)) >= _amount,
            "Insufficient ZOO Balance For Sale"
        );
        require(saleEnabled, "Private Sale Ended");
        require(
            IZoo(zoo).balanceOf(_msgSender()) >= minLimit ||
            _amount >= minLimit,
            "Under Minimum Buy Limit"
        );
        require(
            whitelist[_msgSender()] ||
            IUSDT(zoo).balanceOf(_msgSender()) + _amount <= maxLimit,
            "Above Max Limit"
        );
        // check if the contract received fee
        require(
            IUSDT(usdt).allowance(_msgSender(), address(this)) >=
            ((fee * _amount) / 100),
            "USDT Not Approved"
        );
        IUSDT(usdt).transferFrom(_msgSender(),owner,((fee * _amount) / 100));

        IZoo(zoo).transfer(_msgSender(), _amount);

        totalSale += _amount;

        emit ZooBought(_amount, _msgSender());
    }

    /// @notice Withdraw the accumulated ETH to address
    /// @param _to where the funds should be sent
    function withdraw(address payable _to) external {
        require(
            hasRole(ADMIN, msg.sender) || hasRole(WITHDRAWER_ROLE, msg.sender),
            "Not Allowed"
        );
        _to.transfer(address(this).balance);
        IUSDT(usdt).transfer(_to, IUSDT(usdt).balanceOf(address(this)));
    }

    function withdrawToMarketing(
        address _from,
        address _to,
        uint256 _amount
    ) public onlyAdmin {
        require(IUSDT(usdt).allowance(_from, address(this)) >= _amount);
        IUSDT(usdt).transferFrom(_from, _to, _amount);
    }

    /// @notice Change minting fee
    function setParams(uint256 _fee, address _zoo, address _usdt) external onlyAdmin {
        fee = _fee;
        zoo = _zoo;
        usdt = _usdt;
        emit SetParams(_fee, _zoo, _usdt);
    }

    function setWhitelist(address _user, bool _value) public onlyAdmin {
        whitelist[_user] = _value;
    }

    function checkMintable(address _user, uint256 _amount)
    public
    view
    returns (string memory)
    {
        if (whitelist[_user] == true && _amount >= minLimit) {
            return "Mintable";
        } else {
            if (
                _amount >= minLimit &&
                IUSDT(zoo).balanceOf(_user) + _amount <= maxLimit
            ) {
                return "Mintable";
            } else {
                return "Not Mintable";
            }
        }
    }

    function getIsWhiteListed(address _user) public view returns (bool) {
        return whitelist[_user];
    }

    function setSaleEnabled(bool _value) public onlyAdmin {
        saleEnabled = _value;
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