// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./GasRestrictor.sol";
import "./Gamification.sol";

contract WalletRegistry is Initializable, OwnableUpgradeable {
    GasRestrictor public gasRestrictor;
    Gamification public gamification;

    // dappID => telegram chatID
    mapping(address => string) public telegramChatID;

    struct SecondaryWallet {
        address account;
        string encPvtKey;
        string publicKey;
    }

    // userAddress  => Wallet
    mapping(address => SecondaryWallet) public userWallets;
    // string => userWallet for email users
    mapping(string => SecondaryWallet) public oAuthUserWallets;

    // secondary to primary wallet mapping to get primary wallet from secondary
    mapping(address => address) public getPrimaryFromSecondary;

    uint256 public noOfWallets;

    modifier isValidSender(address from) {
        _isValidSender(from);
        _;
    }

    modifier GasNotZero(address user, bool isOauthUser) {
        _gasNotZero(user, isOauthUser);
        _;
    }

    event WalletCreated(
        address indexed account,
        address secondaryAccount,
        bool isOAuthUser,
        string oAuthEncryptedUserId,
        uint256 walletCount
    );

    function __walletRegistry_init(address _trustedForwarder)
        public
        initializer
    {
        __Ownable_init(_trustedForwarder);
    }

    function _isValidSender(address _from) internal view {
        require(
            _msgSender() == _from ||
                _msgSender() == getSecondaryWalletAccount(_from),
            "INVALID_SENDER"
        );
    }

    function _gasNotZero(address user, bool isOauthUser) internal view {
        if (isTrustedForwarder[msg.sender]) {
            if (!isOauthUser) {
                if (getPrimaryFromSecondary[user] == address(0)) {} else {
                    (, , uint256 u) = gasRestrictor.gaslessData(
                        getPrimaryFromSecondary[user]
                    );
                    require(u != 0, "NOT_ENOUGH_GASBALANCE");
                }
            } else {
                (, , uint256 u) = gasRestrictor.gaslessData(user);
                require(u != 0, "NOT_ENOUGH_GASBALANCE");
            }
        }
    }

    function addGasRestrictorAndGamification(
        GasRestrictor _gasRestrictor,
        Gamification _gamification
    ) external onlyOwner {
        gasRestrictor = _gasRestrictor;
        gamification = _gamification;
    }

    function addTelegramChatID(
        address user, 
        string memory chatID,
        bool isOauthUser
    )
        external isValidSender(user) GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();
        require(bytes(telegramChatID[user]).length == 0, "INVALID_TG_ID"); // INVALID_TELEGRAM_ID
        telegramChatID[user] = chatID;

        _updateGaslessData(gasLeftInit);
    }

    function updateTelegramChatID(
        address user,
        string memory chatID,
        bool isOauthUser
    ) external isValidSender(user) GasNotZero(_msgSender(), isOauthUser)
    {
        uint256 gasLeftInit = gasleft();
        require(bytes(telegramChatID[user]).length != 0, "INVALID_TG_IG"); // INVALID_TELEGRAM_ID
        telegramChatID[user] = chatID;

        _updateGaslessData(gasLeftInit);
    }

    function createWallet(
        address _account,
        string calldata _encPvtKey,
        string calldata _publicKey,
        string calldata oAuthEncryptedUserId,
        bool isOauthUser,
        address referer
    ) external {
        if (!isOauthUser) {
            require(
                userWallets[_msgSender()].account == address(0),
                "ACCOUNT_ALREADY_EXISTS"
            );
            SecondaryWallet memory wallet = SecondaryWallet({
                account: _account,
                encPvtKey: _encPvtKey,
                publicKey: _publicKey
            });
            userWallets[_msgSender()] = wallet;
            getPrimaryFromSecondary[_account] = _msgSender();

            gasRestrictor.initUser(_msgSender(), _account, false);

            // add 2 karma point for _msgSender()
            gamification.addKarmaPoints(_msgSender(), 2);


            if (
                referer != address(0) &&
                getSecondaryWalletAccount(referer) != address(0)
            ) {
                // add 5 karma point for _msgSender()
                // add 5 karma point for referer
                gamification.addKarmaPoints(_msgSender(), 5);
                gamification.addKarmaPoints(referer, 5);

            }
        } else {
            require(
                oAuthUserWallets[oAuthEncryptedUserId].account == address(0),
                "ACCOUNT_ALREADY_EXISTS"
            );
            require(_msgSender() == _account, "Invalid_User");
            SecondaryWallet memory wallet = SecondaryWallet({
                account: _account,
                encPvtKey: _encPvtKey,
                publicKey: _publicKey
            });
            oAuthUserWallets[oAuthEncryptedUserId] = wallet;
            // getPrimaryFromSecondary[_account] = _msgSender();

              // add 2 karma point for _msgSender()
            gamification.addKarmaPoints(_msgSender(), 2);

            if (
                referer != address(0) &&
                getSecondaryWalletAccount(referer) != address(0)
            ) {
                // add 5 karma point for _msgSender()
                // add 5 karma point for referer
                gamification.addKarmaPoints(_msgSender(), 5);
                gamification.addKarmaPoints(referer, 5);

            }

            gasRestrictor.initUser(_msgSender(), _account, true);
        }

        emit WalletCreated(
            _msgSender(),
            _account,
            isOauthUser,
            oAuthEncryptedUserId,
            ++noOfWallets
        );
    }

    function getSecondaryWalletAccount(address _account)
        public
        view
        returns (address)
    {
        return userWallets[_account].account;
    }

    function _updateGaslessData(uint256 _gasLeftInit) internal {
        if (isTrustedForwarder[msg.sender]) {
            gasRestrictor._updateGaslessData(_msgSender(), _gasLeftInit);
        }
    }
}