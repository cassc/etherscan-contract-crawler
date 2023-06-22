//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./access/controllerPanel.sol";
import "./access/vrfConnector.sol";

contract LameloBallNFT is ERC721Enumerable, controllerPanel {
    address public lameloContractAddress;
    address public ec_contract_address;
    IRNG public _iRnd;

    uint256 public cardPrice = 0.22 ether;
    using Strings for uint256;
    mapping(uint16 => uint8) internal tokenData;
    uint256 public creator_fee_percentage = 10;

    // Time conditions
    uint256 public forge_start;
    uint256 public forge_end;
    uint256 public discount_start;
    uint256 public discount_end;
    uint256 public sale_start;
    uint256 public sale_end;
    uint128 public currentIndex = 0;
    uint128 public maxForgeMinted = 0;
    uint128 public maxForge = 131;
    uint128 public maxSold = 0;
    uint128 public maxSupply = 3369;

    bool public setupTime;

    bytes32 internal vrfRequestId;
    uint256 public offset;
    bool public revealLocked = false;

    string public _tokenRevealedBaseURI;
    bytes32 public _reqID;
    bool public _randomReceived;
    string public _tokenPreRevealURI =
        "https://ether-cards.mypinata.cloud/ipfs/QmbmnNycwL1MFpJ1njau331pnARLmwcAWaz8gjCHpxZXv6";

    uint256[] public shares;
    address payable[] wallets;

    event forgeWith(
        uint16 _Gold_Sun,
        uint16 _Silver_Moon,
        uint16 _Blue_Neptune,
        uint16 _Bronze_Saturn
    );

    event buyWithDiscount(
        address indexed _buyer,
        uint8 __amount,
        uint256 __ec_token_id,
        uint256 __melo_token_id
    );

    event buyWithoutDiscount(address indexed _buyer, uint8 __amount);

    event RandomProcessed(uint256 _offset);

    constructor(
        address _lameloContractAddress,
        address _ec_contract_address,
        IRNG _rng
    ) ERC721("LaMelo Ball Collectibles", "LBC") {
        lameloContractAddress = _lameloContractAddress;
        ec_contract_address = _ec_contract_address;
        _iRnd = _rng;
    }

    modifier forgeActive() {
        require(setupTime, "notInitialised");
        require(
            block.timestamp >= forge_start && block.timestamp <= forge_end,
            "!F"
        );
        _;
    }

    modifier forgeEnded() {
        require(setupTime, "notInitialised");
        require(block.timestamp >= forge_end, "!FE");
        _;
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

    function setTime(
        uint256 _discount_start,
        uint256 _sale_start,
        uint256 _forge_start,
        address payable[] memory _wallets,
        uint256[] memory _shares
    ) external onlyAllowed {
        discount_start = _discount_start;
        discount_end = _discount_start + 3 days;
        sale_start = _sale_start;
        sale_end = _sale_start + 8 days;
        forge_start = _forge_start;
        forge_end = _forge_start + 3 days;
        require(_wallets.length == _shares.length, "!length");
        wallets = _wallets;
        shares = _shares;
        setupTime = true;
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
        uint256 _forge_end
    ) external onlyAllowed {
        discount_end = _discount_end;
        sale_end = _sale_end;
        forge_end = _forge_end;
    }

    function setTokenUsed(uint16 _position) internal {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        tokenData[byteNum] = uint8(tokenData[byteNum] | (2**bitPos));
    }

    function isTokenUsed(uint16 _position) public view returns (bool result) {
        uint16 byteNum = uint16(_position / 8);
        uint16 bitPos = uint8(_position - byteNum * 8);
        if (tokenData[byteNum] == 0) return false;
        return tokenData[byteNum] & (0x01 * 2**bitPos) != 0;
    }

    function forge(uint16[] calldata tokenIds) public forgeActive() {
        require(tokenIds.length == 4, "tokenId count.");

        require(1 <= tokenIds[0] && tokenIds[0] <= 500, "err0"); // Gold Sun
        require(501 <= tokenIds[1] && tokenIds[1] <= 1500, "err1"); // Silver Moon
        require(1501 <= tokenIds[2] && tokenIds[2] <= 3500, "err2"); // Blue Neptune
        require(3501 <= tokenIds[3] && tokenIds[3] <= 10000, "err3"); // Bronze Saturn
        // 2 - check ownership
        if (IERC721(lameloContractAddress).ownerOf(tokenIds[0]) != msg.sender) {
            revert("1st");
        }
        if (IERC721(lameloContractAddress).ownerOf(tokenIds[1]) != msg.sender) {
            revert("2nd");
        }
        if (IERC721(lameloContractAddress).ownerOf(tokenIds[2]) != msg.sender) {
            revert("3rd");
        }
        if (IERC721(lameloContractAddress).ownerOf(tokenIds[3]) != msg.sender) {
            revert("4th");
        }

        for (uint16 i = 0; i < tokenIds.length; i++) {
            uint16 thisId = tokenIds[i];

            // 1 - check if token was previously used
            require(!isTokenUsed(thisId), "Forged");
            // register as used
            setTokenUsed(thisId);
        }

        /* 
        Do the Give away.
        */
        require(availableForge() >= 1, "sold out");
        assignCard(msg.sender);
        maxForgeMinted++;
        emit forgeWith(tokenIds[0], tokenIds[1], tokenIds[2], tokenIds[3]);
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

    function adminMint(address _receiver, uint8 loop) public onlyAllowed {
        require((currentIndex + loop) <= 3500, "Overmint");
        for (uint8 i = 0; i < loop; i++) {
            assignCard(_receiver);
        }
    }

    function assignCard(address _receiver) internal {
        currentIndex++;
        _mint(_receiver, currentIndex);
    }

    // ENTRY POINT 1/2 TO SALE CONTRACT
    function buyCard(uint8 _amount) external payable saleActive {
        buyCardInternal(_amount, 0, 0);
        emit buyWithoutDiscount(msg.sender, _amount);
    }

    // ENTRY POINT 2/2 TO SALE CONTRACT
    function buyCardWithDiscount(
        uint8 _amount,
        uint256 _ec_token_id,
        uint256 _melo_token_id
    ) external payable discountActive {
        buyCardInternal(_amount, _ec_token_id, _melo_token_id);
        emit buyWithDiscount(msg.sender, _amount, _ec_token_id, _melo_token_id);
    }

    function buyCardInternal(
        uint8 _amount,
        uint256 _ec_token_id,
        uint256 _melo_token_id
    ) internal {
        uint256 _discount = 0;
        if (_ec_token_id > 0 && _melo_token_id == 0) {
            _discount = getECDiscountPercentage(_ec_token_id);
            require(
                IERC721(ec_contract_address).ownerOf(_ec_token_id) ==
                    msg.sender,
                "!EC"
            );
        } else if (_ec_token_id == 0 && _melo_token_id > 0) {
            _discount = getMeloDiscountPercentage(_melo_token_id);
            require(
                IERC721(lameloContractAddress).ownerOf(_melo_token_id) ==
                    msg.sender,
                "!Lamelo"
            );
        }
        uint256 finalPrice = cardPrice - ((cardPrice / (1000)) * (_discount));
        uint256 balance = _amount * (finalPrice);
        require(msg.value == balance, "Price not met");
        require(availableSales() >= _amount, "sold out");

        for (uint8 i = 0; i < _amount; i++) {
            assignCard(msg.sender);
            maxSold++;
        }
        splitFee(msg.value);
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

    function availableForge() public view returns (uint128) {
        return (maxForge - maxForgeMinted);
    }

    function getECDiscountPercentage(uint256 tokenId)
        public
        pure
        returns (uint256)
    {
        if (tokenId <= 100) {
            return 150;
        }

        if (tokenId <= 1000) {
            return 100;
        }

        if (tokenId <= 10000) {
            return 50;
        }

        return 0;
    }

    function getMeloDiscountPercentage(uint256 tokenId)
        public
        pure
        returns (uint256)
    {
        if (tokenId <= 500) {
            return 200;
        } else if (tokenId <= 1500) {
            return 150;
        } else if (tokenId <= 3500) {
            return 100;
        } else if (tokenId <= 10000) {
            return 50;
        } else {
            return 0;
        }
    }

    function setDataFolder(string memory __tokenPreRevealURI, bool _resetReveal)
        external
        onlyAllowed
    {
        _tokenPreRevealURI = __tokenPreRevealURI;
        if (_resetReveal) {
            offset = 0;
            _randomReceived = false;
            revealLocked = false;
        }
    }

    function uri(uint256 n) public view returns (uint256) {
        return ((n + offset) % maxSupply);
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

    function reveal() external forgeEnded onlyAllowed {
        require(!revealLocked, "locked");
        revealLocked = true;
          _tokenRevealedBaseURI = 'https://client-metadata.ether.cards/api/lamelo2/';
        if (!_randomReceived) _reqID = _iRnd.requestRandomNumberWithCallback();
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
            phase = forge_start;
        } else {
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
        uint256 forge_start;
        uint256 forge_end;
        uint256 discount_start;
        uint256 discount_end;
        uint256 sale_start;
        uint256 sale_end;
        uint256 __availableSales;
        uint256 __availableForge;
    }

    function tellEverything() external view returns (theKitchenSink memory) {
        return
            theKitchenSink(
                forge_start,
                forge_end,
                discount_start,
                discount_end,
                sale_start,
                sale_end,
                availableSales(),
                availableForge()
            );
    }
}