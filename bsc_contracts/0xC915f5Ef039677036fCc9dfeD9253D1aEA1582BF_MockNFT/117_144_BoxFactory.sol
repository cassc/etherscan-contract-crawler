// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GamePadBox is ERC721("BABY-BOX", "BABY-BOX"), Ownable {
    using SafeERC20 for IERC20;

    uint256 public mintFee;

    IERC20 public exchangeToken;

    uint256 public startMintTime;

    address payable public tokenReceiver;

    bool initialized = false;

    uint256 public supplyHard;
    uint256 public mintTotal;

    string private _tokenName;

    string private _tokenSymbol;

    function name() public view virtual override returns (string memory) {
        return _tokenName;
    }

    function symbol() public view virtual override returns (string memory) {
        return _tokenSymbol;
    }

    event Mint(address account, uint256 tokenId);

    function initialize(
        IERC20 _exchangeToken,
        uint256 _mintFee,
        uint256 _startMintTime,
        address payable _tokenReceiver,
        uint256 _supplyHard,
        string memory _name,
        string memory _symbol,
        string memory baseUri,
        address admin
    ) external {
        require(!initialized);
        initialized = true;

        exchangeToken = _exchangeToken;
        mintFee = _mintFee;
        startMintTime = _startMintTime;
        tokenReceiver = _tokenReceiver;
        supplyHard = _supplyHard;
        _setBaseURI(baseUri);
        _tokenName = _name;
        _tokenSymbol = _symbol;
        transferOwnership(admin);
    }

    function setBaseUri(string memory _baseUri) external onlyOwner{
        _setBaseURI(_baseUri);
    }

    function setSupplyHard(uint256 _supplyHard) external onlyOwner {
        require(
            _supplyHard >= mintTotal,
            "GamePadBox: Supply must not be less than what has been produced"
        );
        supplyHard = _supplyHard;
    }

    function mint() external payable {
        require(
            mintTotal < supplyHard,
            "GamePadBox: token haven't been minted."
        );
        require(
            block.timestamp > startMintTime,
            "GamePadBox: It's not the start time"
        );
        mintTotal = mintTotal + 1;
        uint256 tokenId = mintTotal;
        _mint(msg.sender, tokenId);
        if (address(exchangeToken) == address(0)) {
            require(msg.value == mintFee, "GamePadBox: Insufficient payment");
            tokenReceiver.transfer(msg.value);
        } else {
            exchangeToken.safeTransferFrom(msg.sender, tokenReceiver, mintFee);
        }
        emit Mint(msg.sender, tokenId);
    }
}

contract BoxFactory is Ownable {
    event CreateBox(uint256 gid, address boxAddress);
    event CreateGame(uint256 gid, string name);
    event DelGame(uint256 gid);
    event DelBox(uint256 gid, uint256 idx);

    struct GameInfo {
        uint256 gid;
        string name;
        address[] boxes;
    }
    uint256 public gamePadBoxesNumber;
    mapping(uint256 => GameInfo) private gameInfos;

    function gameInfo(uint256 gid)
        public
        view
        returns (string memory name, address[] memory boxes)
    {
        name = gameInfos[gid].name;
        boxes = gameInfos[gid].boxes;
    }

    function createGame(string memory _name) external onlyOwner {
        gamePadBoxesNumber++;
        gameInfos[gamePadBoxesNumber].gid = gamePadBoxesNumber;
        gameInfos[gamePadBoxesNumber].name = _name;

        emit CreateGame(gamePadBoxesNumber, _name);
    }

    function delGame() external onlyOwner {
        require(
            gameInfos[gamePadBoxesNumber].boxes.length == 0,
            "BoxFactory: state that cannot be deleted"
        );

        delete gameInfos[gamePadBoxesNumber];
        emit DelGame(gamePadBoxesNumber--);
    }

    function delBox(uint256 _gid, uint256 _idx) external onlyOwner {
        GameInfo storage info = gameInfos[_gid];
        require(_idx < info.boxes.length, "BoxFactory: index out");
        info.boxes[_idx] = info.boxes[info.boxes.length - 1];
        info.boxes.pop();
        emit DelBox(_gid, _idx);
    }

    function deployPool(
        uint256 gid,
        IERC20 _exchangeToken,
        uint256 _mintFee,
        uint256 _startMintTime,
        address payable _tokenReceiver,
        uint256 _supplyHard,
        string memory _name,
        string memory _symbol,
        string memory baseUri
    ) external onlyOwner {
        GameInfo storage info = gameInfos[gid];
        require(info.gid > 0, "BoxFactory: game has not been created");
        bytes memory bytecode = type(GamePadBox).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(
                _exchangeToken,
                _mintFee,
                _startMintTime,
                _tokenReceiver,
                gamePadBoxesNumber,
                block.number
            )
        );
        address boxAddress;
        assembly {
            boxAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        GamePadBox(boxAddress).initialize(
            _exchangeToken,
            _mintFee,
            _startMintTime,
            _tokenReceiver,
            _supplyHard,
            _name,
            _symbol,
            baseUri,
            owner()
        );
        info.boxes.push(boxAddress);
        emit CreateBox(info.gid, boxAddress);
    }
}