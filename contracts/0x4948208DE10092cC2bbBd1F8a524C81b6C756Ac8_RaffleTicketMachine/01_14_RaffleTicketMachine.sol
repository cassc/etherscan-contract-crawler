// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RaffleTicketMachine is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string baseURI;
    string public baseExtension = "";
    bool contractPaused = false;
    mapping(address => bool) private controllers;
    mapping(uint256 => string) private tokenIdToRaffleName;
    Raffle[] public raffles;
    address public token;
    struct Raffle {
        string raffleName;
        uint256 ticketPriceEth;
        uint256 ticketPriceRandoms;
        SplitPrice splitPrice;
        uint256 quantity;
        uint256 maxQuantity;
        bool paused;
        bool splitMintEnabled;
        bool ethMintEnabled;
        bool randomsMintEnabled;
        uint256 maxQuantityPerMint;
    }
    struct SplitPrice {
        uint256 eth;
        uint256 randoms;
    }

    constructor(address _token, bool _contractPaused)
        ERC721("RaffleTicketMachine", "RDMRFL")
    {
        baseURI = "https://api.therandoms.io/raffles/";
        controllers[msg.sender] = true;
        token = _token;
        contractPaused = _contractPaused;
    }

    modifier onlyController() {
        if (msg.sender == owner()) {
            _;
            return;
        }
        require(controllers[msg.sender], "Caller is not a controller");
        _;
    }

    modifier createRaffleCompliant(string memory _raffleName) {
        bool raffleExists = false;
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                raffleExists = true;
            }
        }
        require(!raffleExists, "Raffle already exists");
        _;
    }

    modifier isPaused(string memory _raffleName) {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                require(!raffles[i].paused, "Raffle is paused");
            }
        }
        _;
    }

    modifier isEthMintEnabled(string memory _raffleName) {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                require(raffles[i].ethMintEnabled, "ETH minting is disabled");
            }
        }
        _;
    }

    modifier isRandomMintEnabled(string memory _raffleName) {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                require(
                    raffles[i].randomsMintEnabled,
                    "Randoms minting is disabled"
                );
            }
        }
        _;
    }

    modifier isSplitMintEnabled(string memory _raffleName) {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                require(
                    raffles[i].splitMintEnabled,
                    "Split minting is disabled"
                );
            }
        }
        _;
    }

    modifier isQuantityAvailable(string memory _raffleName, uint256 _quantity) {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                require(
                    raffles[i].quantity + _quantity <= raffles[i].maxQuantity,
                    "Quantity is too high"
                );
            }
        }
        _;
    }

    modifier isQuantityPerMintValid(
        string memory _raffleName,
        uint256 _quantity
    ) {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                require(
                    _quantity <= raffles[i].maxQuantityPerMint,
                    "Quantity is too high"
                );
            }
        }
        _;
    }

    function setToken(address _token) public onlyController {
        token = _token;
    }

    function setBaseURI(string memory _baseURI) public onlyController {
        baseURI = _baseURI;
    }

    function setBaseExtension(string memory _baseExtension)
        public
        onlyController
    {
        baseExtension = _baseExtension;
    }

    function setController(address _controller, bool _status)
        public
        onlyController
    {
        controllers[_controller] = _status;
    }

    function createRaffle(
        string memory _raffleName,
        uint256 _ticketPriceEth,
        uint256 _ticketPriceRandoms,
        uint256 _splitPriceEth,
        uint256 _splitPriceRandoms,
        uint256 _maxQuantity,
        bool _paused,
        bool _splitMintEnabled,
        bool _ethMintEnabled,
        bool _randomsMintEnabled,
        uint256 _maxQuantityPerMint
    ) public onlyController createRaffleCompliant(_raffleName) {
        raffles.push(
            Raffle(
                _raffleName,
                _ticketPriceEth,
                _ticketPriceRandoms,
                SplitPrice(_splitPriceEth, _splitPriceRandoms),
                0,
                _maxQuantity,
                _paused,
                _splitMintEnabled,
                _ethMintEnabled,
                _randomsMintEnabled,
                _maxQuantityPerMint
            )
        );
    }

    function updateRaffle(
        string memory _raffleName,
        uint256 _ticketPriceEth,
        uint256 _ticketPriceRandoms,
        uint256 _maxQuantity,
        uint256 _splitPriceEth,
        uint256 _splitPriceRandoms,
        bool _paused,
        bool _splitMintEnabled,
        bool _ethMintEnabled,
        bool _randomsMintEnabled,
        uint256 _maxQuantityPerMint
    ) public onlyController {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                raffles[i].ticketPriceEth = _ticketPriceEth;
                raffles[i].ticketPriceRandoms = _ticketPriceRandoms;
                raffles[i].maxQuantity = _maxQuantity;
                raffles[i].splitPrice.eth = _splitPriceEth;
                raffles[i].splitPrice.randoms = _splitPriceRandoms;
                raffles[i].paused = _paused;
                raffles[i].splitMintEnabled = _splitMintEnabled;
                raffles[i].ethMintEnabled = _ethMintEnabled;
                raffles[i].randomsMintEnabled = _randomsMintEnabled;
                raffles[i].maxQuantityPerMint = _maxQuantityPerMint;
            }
        }
    }

    function updateRaffleSplitPrice(
        string memory _raffleName,
        uint256 _eth,
        uint256 _randoms
    ) public onlyController {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                raffles[i].splitPrice.eth = _eth;
                raffles[i].splitPrice.randoms = _randoms;
            }
        }
    }

    function getRaffle(string memory _raffleName)
        public
        view
        returns (
            string memory name,
            uint256 ticketPriceEth,
            uint256 ticketPriceRandoms,
            uint256 splitPriceEth,
            uint256 splitPriceRandoms,
            uint256 quantity,
            uint256 maxQuantity,
            bool paused,
            bool splitMintEnabled,
            bool ethMintEnabled,
            bool randomsMintEnabled
        )
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                return (
                    raffles[i].raffleName,
                    raffles[i].ticketPriceEth,
                    raffles[i].ticketPriceRandoms,
                    raffles[i].splitPrice.eth,
                    raffles[i].splitPrice.randoms,
                    raffles[i].quantity,
                    raffles[i].maxQuantity,
                    raffles[i].paused,
                    raffles[i].splitMintEnabled,
                    raffles[i].ethMintEnabled,
                    raffles[i].randomsMintEnabled
                );
            }
        }
    }

    function getRaffles()
        public
        view
        returns (Raffle[] memory _raffles)
    {
        return raffles;
    }

    function getRafflePaused(string memory _raffleName)
        public
        view
        returns (bool _isPaused)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                return raffles[i].paused;
            }
        }
        return false;
    }

    function getRaffleSplitMintEnabled(string memory _raffleName)
        public
        view
        returns (bool _isSplitMintEnabled)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                return raffles[i].splitMintEnabled;
            }
        }
        return false;
    }

    function getRaffleEthMintEnabled(string memory _raffleName)
        public
        view
        returns (bool _isEthMintEnabled)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                return raffles[i].ethMintEnabled;
            }
        }
        return false;
    }

    function getRaffleRandomsMintEnabled(string memory _raffleName)
        public
        view
        returns (bool isRandomsMintEnabled)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                return raffles[i].randomsMintEnabled;
            }
        }
        return false;
    }

    function getRaffleMaxQuantityPerMint(string memory _raffleName)
        public
        view
        returns (uint256 maxQuantityPerMint)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                return raffles[i].maxQuantityPerMint;
            }
        }
    }

    function getRaffleTicketPriceEth(string memory _raffleName)
        public
        view
        returns (uint256 eth)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                return raffles[i].ticketPriceEth;
            }
        }
    }

    function getRaffleTicketPriceRandoms(string memory _raffleName)
        public
        view
        returns (uint256 randoms)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                return raffles[i].ticketPriceRandoms;
            }
        }
    }

    function getRaffleSplitPrice(string memory _raffleName)
        public
        view
        returns (uint256 eth, uint256 randoms)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                //return two values
                return (
                    raffles[i].splitPrice.eth,
                    raffles[i].splitPrice.randoms
                );
            }
        }
    }

    function ethMint(string memory _raffleName, uint256 _quantity)
        public
        payable
        isPaused(_raffleName)
        isEthMintEnabled(_raffleName)
        isQuantityAvailable(_raffleName, _quantity)
        isQuantityPerMintValid(_raffleName, _quantity)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                require(
                    msg.value >= raffles[i].ticketPriceEth * _quantity,
                    "Not enough ETH sent to mint"
                );
                for (uint256 j = 0; j < _quantity; j++) {
                    string memory raffleName = raffles[i].raffleName;
                    uint256 tokenId = raffles[i].quantity + 1;

                    uint256 fullTokenId = uint256(
                        keccak256(abi.encodePacked(raffleName, tokenId))
                    );
                    _safeMint(msg.sender, fullTokenId);
                    raffles[i].quantity += 1;
                    tokenIdToRaffleName[fullTokenId] = raffleName;
                }
            }
        }
    }

    function randomsMint(string memory _raffleName, uint256 _quantity)
        public
        isPaused(_raffleName)
        isRandomMintEnabled(_raffleName)
        isQuantityAvailable(_raffleName, _quantity)
        isQuantityPerMintValid(_raffleName, _quantity)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                require(
                    IERC20(token).balanceOf(msg.sender) >=
                        raffles[i].ticketPriceRandoms * _quantity,
                    "Not enough Randoms sent to mint"
                );
                IERC20(token).transferFrom(
                    msg.sender,
                    address(this),
                    raffles[i].ticketPriceRandoms * _quantity
                );
                for (uint256 j = 0; j < _quantity; j++) {
                    string memory raffleName = raffles[i].raffleName;
                    uint256 tokenId = raffles[i].quantity + 1;
                    uint256 fullTokenId = uint256(
                        keccak256(abi.encodePacked(raffleName, tokenId))
                    );
                    _safeMint(msg.sender, fullTokenId);
                    raffles[i].quantity += 1;
                    tokenIdToRaffleName[fullTokenId] = raffleName;
                }
            }
        }
    }

    function splitMint(string memory _raffleName, uint256 _quantity)
        public
        payable
        isPaused(_raffleName)
        isSplitMintEnabled(_raffleName)
        isQuantityAvailable(_raffleName, _quantity)
        isQuantityPerMintValid(_raffleName, _quantity)
    {
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(_raffleName))
            ) {
                require(
                    msg.value >= raffles[i].splitPrice.eth * _quantity,
                    "Not enough ETH sent to mint"
                );
                require(
                    IERC20(token).balanceOf(msg.sender) >=
                        raffles[i].splitPrice.randoms * _quantity,
                    "Not enough Randoms to mint"
                );
                IERC20(token).transferFrom(
                    msg.sender,
                    address(this),
                    raffles[i].splitPrice.randoms * _quantity
                );
                for (uint256 j = 0; j < _quantity; j++) {
                    string memory raffleName = raffles[i].raffleName;
                    uint256 tokenId = raffles[i].quantity + 1;
                    uint256 fullTokenId = uint256(
                        keccak256(abi.encodePacked(raffleName, tokenId))
                    );
                    _safeMint(msg.sender, fullTokenId);
                    raffles[i].quantity += 1;
                    tokenIdToRaffleName[fullTokenId] = raffleName;
                }
            }
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory raffleName = tokenIdToRaffleName[_tokenId];
        uint256 tokenId;
        for (uint256 i = 0; i < raffles.length; i++) {
            if (
                keccak256(abi.encodePacked(raffles[i].raffleName)) ==
                keccak256(abi.encodePacked(raffleName))
            ) {
                for (uint256 j = 0; j < raffles[i].quantity; j++) {
                    if (
                        uint256(
                            keccak256(abi.encodePacked(raffleName, j + 1))
                        ) == _tokenId
                    ) {
                        tokenId = j + 1;
                    }
                }
            }
        }
        return
            string(
                abi.encodePacked(baseURI, raffleName, "/", tokenId.toString(), baseExtension)
            );
    }

    function getMaxSupply() public view returns (uint256) {
        uint256 maxSupply = 0;
        for (uint256 i = 0; i < raffles.length; i++) {
            maxSupply += raffles[i].maxQuantity;
        }
        return maxSupply;
    }

    function totalSupply() public view override returns (uint256) {
        uint256 _totalSupply = 0;
        for (uint256 i = 0; i < raffles.length; i++) {
            _totalSupply += raffles[i].quantity;
        }
        return _totalSupply;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function walletOfOwnerUris(address _owner)
        public
        view
        returns (string[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        string[] memory tokensUri = new string[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensUri[i] = tokenURI(tokenOfOwnerByIndex(_owner, i));
        }
        return tokensUri;
    }

    function withdraw() public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
        payable(msg.sender).transfer(address(this).balance);
    }
}