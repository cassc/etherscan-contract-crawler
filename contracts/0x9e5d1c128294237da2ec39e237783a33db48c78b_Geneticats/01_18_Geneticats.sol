//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./access/controllerPanel.sol";
import "./access/vrfConnector.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//// @author: The platform for decentralized communities. - https://galaxis.xyz/

contract Geneticats is ERC721Enumerable, controllerPanel {
    address public ec_contract_address;
    IRNG public _iRnd;

    uint256 public normalPrice = 0.165 ether;
    uint256 public whiteListPrice = 0.15 ether;

    using Strings for uint256;
    address public presigner;

    // Time conditions
    uint256 public discount_start;
    uint256 public discount_end;
    uint256 public sale_start;
    uint256 public sale_end;
    uint256 public reveal_start;

    uint128 public currentIndex = 0;
    uint128 public whiteListSold = 0;
    uint128 public EcSold = 0;

    uint128 public discontMintLimit = 3;

    uint128 public maxSold = 0;
    uint128 public maxSupply = 10000;

    bool public setupTime;

    bytes32 internal vrfRequestId;
    uint256 public offset;
    bool public revealLocked = false;

    string public _tokenRevealedBaseURI;
    bytes32 public _reqID;
    bool public _randomReceived;
    string public _tokenPreRevealURI =
        "https://ether-cards.mypinata.cloud/ipfs/QmZjyP2eKhNsuaK363bpjgtBU7U5XRYL6wpgWDsHAkXWRg";

    uint256[] public shares;
    address payable[] wallets;

    mapping(address => uint256) public whitelist_claimed;

    event WhiteListSale(uint256 tokenCount, address receiver);
    event ECSale(uint256 tokenCount, address receiver, uint256 ecID);
    event buyWithoutDiscount(address _buyer, uint8 __amount);
    event RandomProcessed(uint256 _offset);

    constructor(
        address _ec_contract_address,
        IRNG _rng,
        address _presigner
    ) ERC721("Geneticats", "GTCA") {
        ec_contract_address = _ec_contract_address;
        _iRnd = _rng;
        presigner = _presigner;
    }

    modifier discountActive() {
        require(setupTime, "notInitialised");
        require(
            block.timestamp >= discount_start &&
                block.timestamp <= discount_end,
            "!D"
        );
        _;
    }

    modifier saleActive() {
        require(setupTime, "notInitialised");
        require(
            block.timestamp > sale_start && block.timestamp < sale_end,
            "!S"
        );
        _;
    }

    modifier revealActive() {
        require(setupTime, "notInitialised");
        require(block.timestamp > reveal_start, "!S");
        _;
    }

    function setTime(
        uint256 _discount_start,
        uint256 _sale_start,
        address payable[] memory _wallets,
        uint256[] memory _shares
    ) external onlyAllowed {
        discount_start = _discount_start;
        discount_end = _discount_start + 1 days;
        sale_start = _sale_start;
        sale_end = _sale_start + 7 days;
        reveal_start = sale_end + 1 days;
        require(_wallets.length == _shares.length, "!length");
        wallets = _wallets;
        shares = _shares;
        setupTime = true;
    }

    function changePresigner(address _presigner) external onlyAllowed {
        presigner = _presigner;
    }

    function setWallets(
        address payable[] memory _wallets,
        uint256[] memory _shares
    ) external onlyAllowed {
        require(_wallets.length == _shares.length, "!length");
        wallets = _wallets;
        shares = _shares;
    }

    receive() external payable {
        splitFee(msg.value);
    }

    function extendTime(
        uint256 _discount_end,
        uint256 _sale_end,
        uint256 _reveal_start
    ) external onlyAllowed {
        discount_end = _discount_end;
        sale_end = _sale_end;
        reveal_start = _reveal_start;
    }

    function indexArray(address _user)
        external
        view
        returns (uint256[] memory)
    {
        uint256 sum = this.balanceOf(_user);
        uint256[] memory indexes = new uint256[](sum);

        for (uint256 i = 0; i < sum; i++) {
            indexes[i] = this.tokenOfOwnerByIndex(_user, i);
        }
        return indexes;
    }

    function assignCard(address _receiver) internal {
        currentIndex++;
        _mint(_receiver, currentIndex);
    }

    function adminMint(address _receiver, uint8 loop) public onlyAllowed {
        require((currentIndex + loop) <= maxSupply, "Overmint");
        for (uint8 i = 0; i < loop; i++) {
            assignCard(_receiver);
        }
    }

    function buyCardInternal(uint8 _amount, bool _withDiscount) internal {
        uint256 balance;
        if (_withDiscount) {
            balance = _amount * (whiteListPrice);
        } else {
            balance = _amount * (normalPrice);
        }
        require(msg.value == balance, "Price not met");
        require(availableSales() >= _amount, "sold out");

        for (uint8 i = 0; i < _amount; i++) {
            assignCard(msg.sender);
            maxSold++;
        }
        splitFee(msg.value);
    }

    // ENTRY POINT 1/2 TO SALE CONTRACT
    function buyCard(uint8 _amount) external payable saleActive {
        buyCardInternal(_amount, false);
        emit buyWithoutDiscount(msg.sender, _amount);
    }

    function whiteListBuySignature(
        uint8 _tokenCount,
        bytes memory signature,
        uint256 _ec_token_id // if 0 then use whitelist. if not 0 then use normal
    ) public payable discountActive {
        if (_ec_token_id == 0) {// WHITELIST
            require(verify(msg.sender, signature), "Unauthorised");
            uint256 this_taken = whitelist_claimed[msg.sender] + _tokenCount;
            whitelist_claimed[msg.sender] = this_taken;
            require(
                whitelist_claimed[msg.sender] <= discontMintLimit,
                "whitelist Limit"
            );
            buyCardInternal(_tokenCount, true);

            emit WhiteListSale(_tokenCount, msg.sender);
        } else { // EC
            require(
                IERC721(ec_contract_address).ownerOf(_ec_token_id) ==
                    msg.sender,
                "!EC"
            );
            uint256 this_taken = whitelist_claimed[msg.sender] + _tokenCount;
            whitelist_claimed[msg.sender] = this_taken;
            require(
                whitelist_claimed[msg.sender] <= discontMintLimit,
                "whitelist Limit"
            );
            EcSold += _tokenCount;
            buyCardInternal(_tokenCount, true);
            emit ECSale(_tokenCount, msg.sender, _ec_token_id);
        }
    }

    function splitFee(uint256 amount) internal {
        // duplicated to save an extra call
        bool sent;
        uint256 _total;
        for (uint256 j = 0; j < wallets.length; j++) {
            uint256 _amount = (amount * shares[j]) / 1000;
            if (j == wallets.length - 1) {
                _amount = amount - _total;
            } else {
                _total += _amount;
            }
            (sent, ) = wallets[j].call{value: _amount}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
        }
    }

    function availableSales() public view returns (uint128) {
        return (maxSupply - maxSold);
    }

    function setDataFolder(
        string memory __tokenPreRevealURI,
        string memory __tokenRevealedBaseURI,
        bool _resetReveal
    ) external onlyAllowed {
        _tokenPreRevealURI = __tokenPreRevealURI;
        _tokenRevealedBaseURI = __tokenRevealedBaseURI;
        if (_resetReveal) {
            offset = 0;
            _randomReceived = false;
            revealLocked = false;
        }
    }

    function uri(uint256 n) public view returns (uint256) {
        return ((n + offset) % maxSupply);
    }

    function reveal() external revealActive onlyAllowed {
        require(!revealLocked, "locked");
        revealLocked = true;
     //    _tokenRevealedBaseURI = "https://geneticats-metadata-staging.herokuapp.com/api/metadata/";
        _tokenRevealedBaseURI = "https://geneticats-metadata-server.ether.cards/api/metadata/";
        if (!_randomReceived) _reqID = _iRnd.requestRandomNumberWithCallback();
    }

    function process(uint256 random, bytes32 reqID) external {
        require(msg.sender == address(_iRnd), "Unauthorised RNG");
        if (_reqID == reqID) {
            require(!(_randomReceived), "Random No. already received");
            offset = random % (maxSupply + 1);
            emit RandomProcessed(offset);
            _randomReceived = true;
        } else revert("Incorrect request ID sent");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");
        string memory revealedBaseURI = _tokenRevealedBaseURI;

        if (!_randomReceived) return _tokenPreRevealURI;

        uint256 newTokenId = uri(tokenId);

        string memory folder = (newTokenId % 100).toString();
        string memory file = newTokenId.toString();
        string memory slash = "/";
        return string(abi.encodePacked(revealedBaseURI, folder, slash, file));
        //
    }

    function verify(address _user, bytes memory _signature)
        public
        view
        returns (bool)
    {
        require(_user != address(0), "NativeMetaTransaction: INVALID__user");
        bytes32 _hash =
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_user)));
        require(_signature.length == 65, "Invalid signature length");
        address recovered = ECDSA.recover(_hash, _signature);
        return (presigner == recovered);
    }

    function how_long_more(uint8 _phase)
        public
        view
        returns (
            uint256 Days,
            uint256 Hours,
            uint256 Minutes,
            uint256 Seconds
        )
    {
        uint256 phase;
        if (_phase == 1) {
            phase = discount_start;
        } else if (_phase == 2) {
            phase = sale_start;
        } else if (_phase == 3) {
            phase = reveal_start;
        }else {
            return (0, 0, 0, 0);
        }
        require(block.timestamp < phase, "Started");
        uint256 gap = phase - block.timestamp;
        Days = gap / (24 * 60 * 60);
        gap = gap % (24 * 60 * 60);
        Hours = gap / (60 * 60);
        gap = gap % (60 * 60);
        Minutes = gap / 60;
        Seconds = gap % 60;
        return (Days, Hours, Minutes, Seconds);
    }

    struct theKitchenSink {
        uint256 discount_start;
        uint256 discount_end;
        uint256 sale_start;
        uint256 sale_end;
        uint256 reveal_start;
        uint256 __availableSales;
    }

    function tellEverything() external view returns (theKitchenSink memory) {
        return
            theKitchenSink(
                discount_start,
                discount_end,
                sale_start,
                sale_end,
                reveal_start,
                availableSales()
            );
    }
}