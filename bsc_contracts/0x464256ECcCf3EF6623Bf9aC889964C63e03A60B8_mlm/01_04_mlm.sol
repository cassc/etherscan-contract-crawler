// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//welcome to https://mlmdefi.com
contract mlm is Initializable {
    struct User {
        uint grade;
        uint expireTime;
        address upline;
        string domain;
    }
    mapping(address => User) public userData;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public allowToken;
    mapping(address => uint) public reward;
    mapping(address => mapping(address => uint)) public userIncome;
    mapping(address => mapping(address => uint)) public userWithdraw;
    mapping(string => address) public domain;

    address public market;
    address public verifySigner;
    address public nft;

    uint[] public rate;
    uint[] public gradeRate;
    uint[] public joinAmount;
    uint[] public commissionLevel;

    uint public nonce;
    uint public autoUpgrade;

    event Join(
        address indexed sender,
        address indexed upline,
        uint grade,
        uint amount,
        string domain
    );
    event Claim(address indexed to, address token, uint amount);
    event JoinPartner(
        address indexed sender,
        address indexed upline,
        uint grade,
        string domain
    );
    event Upgrade(address indexed sender, uint grade, uint amount);
    event Renew(address indexed sender, uint amount);

    modifier checkToken(address token) {
        require(allowToken[token], "Token not allow");
        _;
    }

    modifier onlyEOAorWhitelist() {
        require(
            whitelist[msg.sender] || msg.sender == tx.origin,
            "must be EOA"
        );
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "X");
        _;
    }

    modifier checkDomain(string memory d) {
        require(
            bytes(d).length > 2 &&
                bytes(d).length < 16 &&
                domain[d] == address(0),
            "Domain invalid"
        );
        _;
    }

    function initialize() public initializer {
        rate = [50, 20, 10, 5, 5, 4, 3, 2, 1];
        gradeRate = [40, 50, 60, 70, 80, 90];
        joinAmount = [
            0,
            9.9 ether,
            49.9 ether,
            99.9 ether,
            149.9 ether,
            199.9 ether
        ];
        commissionLevel = [1, 3, 6, 9, 9, 9];
        autoUpgrade = 3;
        whitelist[msg.sender] = true;
        verifySigner = 0xf6FA0E78F5C1244E34d85362C1043890d4170976;
        allowToken[0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = true;
        allowToken[0x55d398326f99059fF775485246999027B3197955] = true;
        allowToken[0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d] = true;
        market = 0x13Eb6DBc545f6f35a6F18dE0D94a3628A0890325;
        domain["www"] = 0x13Eb6DBc545f6f35a6F18dE0D94a3628A0890325;
    }

    function setAllowToken(address token, bool status) external onlyWhitelist {
        allowToken[token] = status;
    }

    function setSigner(address _signer) external onlyWhitelist {
        verifySigner = _signer;
    }

    function setWhitelist(address _addr, bool _status) external onlyWhitelist {
        whitelist[_addr] = _status;
    }

    function joinPartner(
        string memory _domain,
        uint _grade,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external virtual onlyEOAorWhitelist checkDomain(_domain) returns (bool) {
        require(
            verify(msg.sender, _grade, _domain, r, s, v),
            "Signer not match"
        );
        User memory _user = User({
            upline: market,
            grade: _grade,
            domain: _domain,
            expireTime: block.timestamp + 365 days
        });
        userData[msg.sender] = _user;
        domain[_domain] = msg.sender;
        nonce++;
        emit JoinPartner(msg.sender, market, _grade, _domain);
        return true;
    }

    function join(
        address _token,
        address _upline,
        uint _grade,
        string memory _domain
    )
        external
        virtual
        checkToken(_token)
        checkDomain(_domain)
        onlyEOAorWhitelist
        returns (bool)
    {
        require(userData[_upline].upline != address(0), "Upline not found");
        require(_grade < gradeRate.length, "Invalid Grade");
        uint amount = joinAmount[_grade];
        uint grade = _grade;
        if (amount > 0) {
            require(
                IERC20(_token).transferFrom(msg.sender, address(this), amount),
                "Transfer failed"
            );
            distribution(_token, amount, _upline);
            User memory parentInfo = userData[_upline];
            if (
                parentInfo.grade > autoUpgrade - 1 &&
                parentInfo.grade > _grade &&
                _grade < gradeRate.length - 1
            ) {
                grade = _grade + 1;
            }
        }
        User memory _user = User({
            upline: _upline,
            grade: grade,
            domain: _domain,
            expireTime: grade == 0
                ? block.timestamp + 30 days
                : block.timestamp + 365 days
        });
        userData[msg.sender] = _user;
        domain[_domain] = msg.sender;
        emit Join(msg.sender, _upline, grade, amount, _domain);
        return true;
    }

    function distribution(
        address token,
        uint amount,
        address _upline
    ) internal {
        uint total = 0;
        uint commission = 0;
        uint suplus = 0;
        User memory parentInfo = userData[_upline];
        commission = (amount * gradeRate[parentInfo.grade]) / 100;
        if (parentInfo.expireTime > block.timestamp) {
            userIncome[_upline][token] += commission;
            total += commission;
        }
        suplus = amount * 2 - commission * 2;
        for (uint i = 1; i < rate.length; i++) {
            _upline = parentInfo.upline;
            if (_upline == address(0) || _upline == market) {
                break;
            }
            parentInfo = userData[_upline];
            if (parentInfo.expireTime < block.timestamp) {
                continue;
            }
            if (commissionLevel[parentInfo.grade] > i) {
                commission = (suplus * rate[i]) / 100;
                userIncome[_upline][token] += commission;
                total += commission;
            }
        }
        suplus = amount - total;
        if (suplus > 0) {
            reward[token] += suplus;
        }
    }

    function upgrade(
        uint _grade,
        address _token
    ) external virtual checkToken(_token) onlyEOAorWhitelist returns (bool) {
        uint payAmount = upgradeNeedAmount(_grade, msg.sender);
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), payAmount),
            "Transfer failed"
        );
        distribution(_token, payAmount, userData[msg.sender].upline);
        userData[msg.sender].grade = _grade;
        userData[msg.sender].expireTime =
            userData[msg.sender].expireTime +
            365 days;
        emit Upgrade(msg.sender, _grade, payAmount);
        return true;
    }

    function upgradeNeedAmount(
        uint _grade,
        address _user
    ) public view returns (uint payAmount) {
        User memory userInfo = userData[_user];
        require(
            userInfo.upline != address(0) &&
                _grade > userInfo.grade &&
                _grade < gradeRate.length,
            "Invalid Grade"
        );
        uint amount = joinAmount[_grade];
        uint oldAmount = joinAmount[userInfo.grade];
        payAmount = amount - oldAmount;
    }

    function renew(address token) external checkToken(token) returns (bool) {
        User storage userInfo = userData[msg.sender];
        if (userInfo.grade == 0) {
            userInfo.expireTime = block.timestamp + 30 days;
        } else {
            require(
                IERC20(token).transferFrom(
                    msg.sender,
                    address(this),
                    joinAmount[userInfo.grade]
                ),
                "Transfer failed"
            );
            distribution(
                token,
                joinAmount[userInfo.grade],
                userData[msg.sender].upline
            );
            userInfo.expireTime = userInfo.expireTime + 365 days;
        }
        emit Renew(msg.sender, joinAmount[userInfo.grade]);
        return true;
    }

    function claimAll(
        address[] memory _token
    ) external virtual onlyEOAorWhitelist returns (bool) {
        for (uint i = 0; i < _token.length; i++) {
            claim(_token[i]);
        }
        return true;
    }

    function claim(
        address _token
    ) public virtual checkToken(_token) returns (bool) {
        uint amount = userIncome[msg.sender][_token] -
            userWithdraw[msg.sender][_token];
        userWithdraw[msg.sender][_token] += amount;
        require(IERC20(_token).transfer(msg.sender, amount), "Transfer failed");
        emit Claim(msg.sender, _token, amount);
        return true;
    }

    function claimReward(address _token) external virtual onlyWhitelist {
        uint amount = reward[_token];
        reward[_token] = 0;
        require(IERC20(_token).transfer(msg.sender, amount), "Transfer failed");
    }

    function calculator(
        uint _mygrade,
        uint _joingrade,
        uint _level,
        uint _usernum
    ) external view virtual returns (uint _amount) {
        if (_mygrade < 3) {
            uint fixed_level = _mygrade * 3;
            _level = fixed_level < _level ? fixed_level : _level;
        }
        uint join_amount = joinAmount[_joingrade];
        _amount = (gradeRate[_mygrade] * join_amount * _usernum) / 100;
        for (uint i = 1; i < _level; i++) {
            _amount += ((join_amount * rate[i]) / 100) * (_usernum ** (i + 1));
        }
    }

    function calculatorMyCommission(
        address _upline,
        address _downline,
        uint _amount
    ) public view returns (uint amount) {
        User memory userInfo = userData[_downline];
        User memory parentInfo = userData[userInfo.upline];
        uint commission = (_amount * gradeRate[parentInfo.grade]) / 100;
        if (userInfo.upline == _upline) {
            return commission;
        }
        uint suplus = _amount * 2 - commission * 2;
        for (uint i = 1; i < rate.length; i++) {
            userInfo = userData[userInfo.upline];
            if (userInfo.upline == _upline) {
                parentInfo = userData[userInfo.upline];
                if (commissionLevel[parentInfo.grade] > i) {
                    amount = (suplus * rate[i]) / 100;
                    return amount;
                }
            }
        }
    }

    function getMessageHash(
        address _user,
        uint _amount,
        string memory _str
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _amount, _str, nonce));
    }

    function verify(
        address _user,
        uint _amount,
        string memory _str,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal view returns (bool) {
        bytes32 messageHash = getMessageHash(_user, _amount, _str);

        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        return ecrecover(ethSignedMessageHash, v, r, s) == verifySigner;
    }
}