// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../../contracts/Common/Admin.sol";
import "../../contracts/Interfaces/IHelper.sol";
import "../../contracts/Interfaces/IUSDT.sol";
import "../../contracts/Interfaces/IMyERC20.sol";

contract NemoLand is Admin, ERC721Upgradeable {
    struct OnSaleLand {
        uint256 price;
        address saleOwner;
        uint256 currencyType;
    }

    struct TokenInfo {
        uint256 currencyType;
        address paytoken;
        bool isReturnsBool;
        mapping(uint256 => uint256) zoneIdToPrice;
    }

    mapping(uint256 => TokenInfo) public AllowedCrypto;

    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 6553610;
    uint256 public commission;
    address payable public receivingWallet;
    address private signer_;
    IHelper public helper;
    string private baseTokenURI;
    uint256[] private tokensOnSale;
    mapping(uint256 => OnSaleLand) public tokenIdToPrice;
    mapping(uint256 => uint256[]) public stateToLands;
    mapping(uint256 => uint256) public landToState;

    event LandMint(
        uint256 indexed state,
        uint256 indexed land,
        uint256 indexed referral,
        uint256 currencyType
    );
    event DisallowBuy(address indexed owner, uint256 indexed id);
    event ZonePrice(
        uint256 indexed zone,
        uint256 indexed weiAmount,
        uint256 indexed currencyType
    );
    event Resale(
        uint256 indexed id,
        uint256 indexed weiPrice,
        uint256 indexed weiCom,
        uint256 currencyType
    );
    event Commission(uint256 indexed commission);
    event AllowBuy(
        address indexed owner,
        uint256 indexed id,
        uint256 indexed weiAmount,
        uint256 currencyType
    );

    event CurrencyAdded(uint256 currencyType, address paytoken);

    function initialize(
        string memory _baseURI,
        string memory _name,
        string memory _symbol,
        address payable _receivingWallet,
        address admin,
        address signer,
        IHelper _helper,
        address[] memory _currencyAddresses,
        bool[] memory _isReturnsBool,
        uint256 _resaleCom,
        uint256[][2] memory zonePricing
    ) public initializer {
        __ERC721_init(_name, _symbol);
        require(_receivingWallet != address(0), "");
        require(admin != address(0), "");
        require(_resaleCom > 0, "");
        commission = _resaleCom;
        receivingWallet = _receivingWallet;
        admin_ = admin;
        signer_ = signer;
        setBaseTokenURI(_baseURI);
        helper = _helper;
        for (
            uint256 currencyType = 0;
            currencyType < zonePricing.length;
            currencyType++
        ) {
            addCurrency(
                currencyType + 1,
                _currencyAddresses[currencyType],
                _isReturnsBool[currencyType],
                zonePricing[currencyType]
            );
        }
    }

    /// @notice Adds new token as a currency
    /// @param _currecyType currency type in 1-ETH, 2-USDT, can add more.
    /// @param _paytoken address of the token's contract address
    /// @param _isReturnsBool tranferFrom method returns bool or not
    /// @param _zoneValue [0,zone1,zone2,zone3,zone4,zone5, so on]
    function addCurrency(
        uint256 _currecyType,
        address _paytoken,
        bool _isReturnsBool,
        uint256[] memory _zoneValue
    ) public onlyAdmin {
        require(_currecyType > 0, "Invalid Type");
        require(
            AllowedCrypto[_currecyType].currencyType == 0,
            "Type alredy Exists"
        );
        TokenInfo storage newToken = AllowedCrypto[_currecyType];
        newToken.currencyType = _currecyType;
        newToken.paytoken = _paytoken;
        newToken.isReturnsBool = _isReturnsBool;

        for (uint256 zone = 1; zone < _zoneValue.length; zone++) {
            newToken.zoneIdToPrice[zone] = _zoneValue[zone];
        }
        emit CurrencyAdded(_currecyType, _paytoken);
    }

    /// @dev Change the Signer to be `newSigner`.
    /// @param newSigner address of the new Signer.
    function changeSigner(address newSigner) external onlyAdmin {
        signer_ = newSigner;
    }

    /// @dev Change the Helper to be `newHelper`.
    /// @param newHelper address of the new Helper Contract.
    function changeHelper(address newHelper) external onlyAdmin {
        helper = IHelper(newHelper);
    }

    /// @notice set the wallet receiving the proceeds
    /// @param newWallet address of the new receiving wallet
    function setReceivingWallet(address payable newWallet) external onlyAdmin {
        require(newWallet != address(0), "Invalid RW");
        receivingWallet = newWallet;
    }

    /// @notice sets Zone price
    /// @param currencyType price of Land in particular currency
    /// @param zoneId price of Land in particular Zone
    /// @param amount price of Land in particular Zone particular currency
    function setZonePrice(
        uint256 currencyType,
        uint256 zoneId,
        uint256 amount
    ) external onlyAdmin {
        AllowedCrypto[currencyType].zoneIdToPrice[zoneId] = amount;
        emit ZonePrice(zoneId, amount, currencyType);
    }

    /**
     * @notice Mint a new lands
     * @param _signature The signature to validate input data (ZoneId,id,sender)
     * @param lands ids of the new lands
     * @param _zoneId 0 param is ZoneId & 1 is Num of lands in that zone
     * @param currencyType in which land to be bought
     * @param _amount amount of currency to buy lands
     * @param referral Referral code of Sales Agent
     */
    function mintLand(
        bytes calldata _signature,
        uint256 state,
        uint256[] memory lands,
        uint256[2][] memory _zoneId,
        uint256 currencyType,
        uint256 _amount,
        uint256 referral
    ) external payable {
        require(
            isValidRequest(
                _signature,
                state,
                lands,
                _zoneId,
                currencyType,
                referral
            ),
            "Invalid sign"
        );
        if (state > 0) {
            require(stateToLands[state].length == 0, "State already exists");
        }
        uint256 amtRequired = 0;
        uint256 counter = 0;
        for (counter = 0; counter < _zoneId.length; counter++) {
            amtRequired =
                amtRequired +
                AllowedCrypto[currencyType].zoneIdToPrice[_zoneId[counter][0]] *
                _zoneId[counter][1];
        }

        for (counter = 0; counter < lands.length; counter++) {
            require(_exists(lands[counter]) == false, "Land exists");
            require(lands[counter] <= MAX_SUPPLY, "MAX_SUPPLY");
            require(landToState[lands[counter]] == 0, "Exists in State");
        }

        if (1 == currencyType) {
            require(msg.value >= amtRequired, "not enough eth sent");
            uint256 leftOver = msg.value - amtRequired;

            if (leftOver > 0) {
                payable(msg.sender).transfer(leftOver);
            }
            payable(receivingWallet).transfer(amtRequired);
        } else {
            require(_amount >= amtRequired, "not enough eth sent");

            if (AllowedCrypto[currencyType].isReturnsBool) {
                IMyERC20 paytoken = IMyERC20(
                    AllowedCrypto[currencyType].paytoken
                );
                paytoken.transferFrom(msg.sender, receivingWallet, amtRequired);
            } else {
                IUSDT paytoken = IUSDT(AllowedCrypto[currencyType].paytoken);
                paytoken.transferFrom(msg.sender, receivingWallet, amtRequired);
            }
        }

        if (state > 0) {
            stateToLands[state] = lands;
            _mint(msg.sender, state);
            for (counter = 0; counter < lands.length; counter++) {
                landToState[lands[counter]] = state;
                emit LandMint(state, lands[counter], referral, currencyType);
            }
        } else {
            for (counter = 0; counter < lands.length; counter++) {
                _mint(msg.sender, lands[counter]);
                emit LandMint(state, lands[counter], referral, currencyType);
            }
        }
    }

    /**
     * @notice Listing `_id` for sale
     * @param _id Id of land to put on sale
     * @param amount Price for sale
     * @param currencyType currency Type in which NFT owner wants to sell theis NFT
     */
    function allowBuy(
        uint256 _id,
        uint256 amount,
        uint256 currencyType
    ) external {
        require(msg.sender == ownerOf(_id), "Not an Owner");
        require(amount > 0, "Invalid Price");
        require(tokenIdToPrice[_id].price == 0, "Already On sale");
        tokensOnSale.push(_id);
        tokenIdToPrice[_id] = OnSaleLand(amount, msg.sender, currencyType);
        emit AllowBuy(msg.sender, _id, amount, currencyType);
    }

    /**
     * @notice Deletes Listing of `_id` on sale
     * @param _id Id of land to to remove from sale
     */
    function disallowBuy(uint256 _id) external {
        require(msg.sender == ownerOf(_id), "Not an Owner");
        require(tokenIdToPrice[_id].price > 0, "Not for sale");
        removefromSale(_id);
        emit DisallowBuy(msg.sender, _id);
    }

    /**
     * @notice Buy Land which if available for sale
     * @param _id Id of land to buy
     */
    function buy(uint256 _id, uint256 _amount) external payable {
        uint256 price = tokenIdToPrice[_id].price;

        require(price > 0, "Not for sale");
        uint256 currencyType = tokenIdToPrice[_id].currencyType;
        address seller = tokenIdToPrice[_id].saleOwner;
        uint256 comission;
        uint256 leftOver;
        if (1 == currencyType) {
            require(msg.value == price, "Invalid price");
            _transfer(seller, msg.sender, _id);
            removefromSale(_id);
            comission = (msg.value * commission) / 100;
            leftOver = msg.value - comission;
            payable(receivingWallet).transfer(comission);
            payable(seller).transfer(leftOver);
        } else {
            require(_amount == price, "Invalid price");
            _transfer(seller, msg.sender, _id);
            removefromSale(_id);
            comission = (_amount * commission) / 100;
            leftOver = _amount - comission;

            if (AllowedCrypto[currencyType].isReturnsBool) {
                IMyERC20 paytoken = IMyERC20(
                    AllowedCrypto[currencyType].paytoken
                );
                paytoken.transferFrom(msg.sender, receivingWallet, comission);
                paytoken.transferFrom(msg.sender, seller, leftOver);
            } else {
                IUSDT paytoken = IUSDT(AllowedCrypto[currencyType].paytoken);
                paytoken.transferFrom(msg.sender, receivingWallet, comission);
                paytoken.transferFrom(msg.sender, seller, leftOver);
            }
        }
        emit Resale(_id, leftOver, comission, currencyType);
    }

    /// @dev Change the commission to be `resaleCom_`
    /// @param resaleCom_ The new Commission percenrtage to be sent to receivingWallet.
    function setResaleCom(uint256 resaleCom_) external onlyAdmin {
        commission = resaleCom_;
        emit Commission(resaleCom_);
    }

    function allLandsOfState(uint256 stateId)
        external
        view
        returns (uint256[] memory)
    {
        require(stateToLands[stateId].length != 0, "Invalid State");
        return stateToLands[stateId];
    }

    /// @notice called when Admin wants to withdraw contract balance
    function withdraw() public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        (bool success, ) = (receivingWallet).call{value: balance}("");
        require(success, "Transfer failed");
    }

    /// @dev Change the baseTokenURI to be `_baseURI`
    /// @param _baseURI The new base URI of all the tokens
    function setBaseTokenURI(string memory _baseURI) public onlyAdmin {
        baseTokenURI = _baseURI;
    }

    function getAllLandsOnSale() public view returns (uint256[] memory) {
        return tokensOnSale;
    }

    /**
     * @notice Return the URI of a specific token
     * @param id The id of the token
     * @return The URI of the token
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(id),
                    "/metadata.json"
                )
            );
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`. This imposes no restrictions on msg.sender.
     * @param from Owner of the token
     * @param to `to` cannot be the zero address.
     * @param tokenId `tokenId` token must be owned by `from`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );

        _transfer(from, to, tokenId);
        if (tokenIdToPrice[tokenId].price > 0) {
            removefromSale(tokenId);
        }
    }

    /// @notice Check all lands were owned by single user
    /// @param ids list of lands owned by single user
    /// @return Single owner of all Lands, success
    function ownerOfState(uint256[] calldata ids)
        public
        view
        returns (address, bool)
    {
        address landOwner = ownerOf(ids[0]);

        if (ids.length != 1) {
            for (uint256 counter = 1; counter < ids.length; counter++) {
                if (landOwner != ownerOf(ids[counter])) {
                    return (address(0), false);
                }
            }
        }
        return (landOwner, true);
    }

    /// @notice Check all lands were owned by single user
    /// @param currencyType price of Land in particular currency
    /// @param zone price of Land in particular Zone
    /// @return Price of Zone in particular Currency
    function getZonePrice(uint256 currencyType, uint256 zone)
        public
        view
        returns (uint256)
    {
        return AllowedCrypto[currencyType].zoneIdToPrice[zone];
    }

    function removefromSale(uint256 _id) internal {
        delete tokenIdToPrice[_id];
        uint256 index;
        for (uint256 counter = 0; counter < tokensOnSale.length; counter++) {
            if (tokensOnSale[counter] == _id) {
                index = counter;
                break;
            }
        }
        tokensOnSale[index] = tokensOnSale[tokensOnSale.length - 1];
        tokensOnSale.pop();
    }

    function isValidRequest(
        bytes calldata _signature,
        uint256 _state,
        uint256[] memory _id,
        uint256[2][] memory _zoneId,
        uint256 currencyType,
        uint256 referral
    ) internal view returns (bool) {
        bytes32 msgHash = keccak256(
            abi.encode(_state, _id, _zoneId, currencyType, msg.sender, referral)
        );
        bool isValid = msgHash.toEthSignedMessageHash().recover(_signature) ==
            signer_;
        return isValid;
    }
}