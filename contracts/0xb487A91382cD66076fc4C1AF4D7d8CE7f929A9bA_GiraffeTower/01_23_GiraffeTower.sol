// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GiraffeTower is ERC721PresetMinterPauserAutoId {
    string private _currentBaseURI;
    bool public preSaleStatus;
    bool public mainSaleStatus;
    address private ownerAddress;
    uint256 public round;
    uint256 public preSaleCount = 0;
    uint256 public publicSaleCount = 0;
    uint256 public stotalSupply = 100;
    uint256 public maxItemsPerPreSale = 5; // Mutable by owner
    uint256 public preSaleMaxItems = 3000;
    uint256 public mintPrice = 0.05 ether;
    uint256 public maxItemsPerTx = 5; // Mutable by owner
    uint256 public adoptionsCount = 800;
    uint256 public OgsCount = 100;
    uint256 totalDividends = 0;
    using Address for address;
    uint256 private maxToken;
    string private _currentGatewayURI;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    mapping(uint256 => address) public Ogs; //Maps address to their tokenId
    mapping(uint256 => bool) public addressExist; //Stores if address exist;
    mapping(address => uint256) public preMints; // Maps address to how many they can premint
    mapping(uint256 => uint256) tokenRound;
    mapping(uint256 => uint256) tokenAdoption;
    mapping(uint256 => uint256) staticTokenAdoption;
    mapping(uint256 => address) public genesisAddress;
    event Mint(address indexed owner, uint256 indexed tokenId);
    event Received(address, uint256);
    uint256 ownerRoyalty = 0;
    struct Giraffe {
        uint256 birthday;
    }
    mapping(uint256 => Giraffe) public giraffes;

    constructor()
        ERC721PresetMinterPauserAutoId(
            "Giraffe Tower",
            "GT",
            "https://ipfs.io/ipfs/QmUtvDXWka1wSJkPFWMGtVv2K6fRPcVLxZQkqinpBqjPWv/"
        )
    {
        ownerAddress = msg.sender;
        maxToken = 10000;
        setGateway("https://ipfs.io/ipfs/");
        preSaleStatus = false;
        mainSaleStatus = false;
    }

    function owner() public view returns (address) {
        return ownerAddress;
    }

    function _ownerRoyalty() public view returns (uint256) {
        return ownerRoyalty;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
        uint256 tt = msg.value / 100;
        totalDividends += tt;
        uint256 ot = msg.value - tt;
        ownerRoyalty += ot;
    }

    function withdrawReward(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender && tokenId <= 100, "WR:Invalid");
        uint256 total = (totalDividends - tokenRound[tokenId]) / OgsCount;
        require(total > 0,"Too Low");
        tokenRound[tokenId] = totalDividends;
        sendEth(msg.sender, total);
    }

    function withdrawAllReward() external {
        address _address = msg.sender;
        uint256[] memory _tokensOwned = walletOfOwner(_address);
        uint256 totalClaim;
        for (uint256 i; i < _tokensOwned.length; i++) {
            if (_tokensOwned[i] <= 100) {
                totalClaim +=
                    (totalDividends - tokenRound[_tokensOwned[i]]) /
                    OgsCount;
                tokenRound[_tokensOwned[i]] = totalDividends;
            }
        }
        require(totalClaim > 0, "WAR: LTC");
        sendEth(msg.sender, totalClaim);
    }

    function withdrawRoyalty() external ownerOnly {
        require(ownerRoyalty > 0, "WRLTY:Invalid");
        uint256 total = ownerRoyalty;
        ownerRoyalty = 0;
        sendEth(msg.sender, total);
    }

    function preSale() external payable {
        require(preSaleStatus, "preSale: Paused");
        require(msg.sender == tx.origin, "Not Allowed");
        uint256 remainder = msg.value % mintPrice;
        uint256 amount = msg.value / mintPrice;
        require(msg.value > 0, "preSale: Invalid Value");
        require(remainder == 0, "preSale: Send a divisible amount of eth");
        require(
            preSaleCount + amount <= preSaleMaxItems,
            "preSale: Surpasses cap"
        );
        require(
            amount <= preMints[msg.sender],
            "preSale: Amount greater than allocation"
        );
        preSaleCount += amount;
        preMints[msg.sender] -= amount;
        _mintWithoutValidation(msg.sender, amount);
    }

    function adoptionMint() external {
        uint256 tokenCount = balanceOf(msg.sender);
        require(tokenCount > 0, "adoptionMint: You don't own any token");
        for (uint256 i; i < tokenCount; i++) {
            uint256 tokenid = tokenOfOwnerByIndex(msg.sender, i);
            if (tokenid <= 100) {
                uint256 adoptions = tokenAdoption[tokenid];
                if (adoptions > 0) {
                    tokenAdoption[tokenid] -= adoptions;
                    _mintWithoutValidation(msg.sender, adoptions);
                }
            }
        }
    }

    function _mintWithoutValidation(address to, uint256 amount) internal {
        require(totalSupply() < maxToken,"Mint: Surpasses cap");
        for (uint256 i = 0; i < amount; i++) {
            stotalSupply += 1;
            genesisAddress[stotalSupply] = to;
            _safeMint(to, stotalSupply);
            tokenRound[stotalSupply] = 0;
            // _mint(to, totalSupply);
            giraffes[stotalSupply] = Giraffe(block.timestamp);
            emit Mint(to, stotalSupply);
        }
    }

    function publicSale() external payable {
        require(mainSaleStatus, "publicMint: Paused");
        require(msg.sender == tx.origin, "Not Allowed");
        uint256 remainder = msg.value % mintPrice;
        uint256 amount = msg.value / mintPrice;
        require(remainder == 0, "publicMint: Send a divisible amount of eth");
        require(msg.value > 0, "publicMint: Invalid Value");
        require(amount <= maxItemsPerTx, "publicMint: Max 5 per tx");

        require(
            OgsCount + adoptionsCount + preSaleCount + publicSaleCount + amount <= maxToken,
            "publicMint: Surpasses cap"
        );
        publicSaleCount += amount;
        _mintWithoutValidation(msg.sender, amount);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function _gatewayURI() internal view virtual returns (string memory) {
        return _currentGatewayURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        // string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        string memory gateway = _gatewayURI();

        return
            string(
                abi.encodePacked(
                    gateway,
                    base,
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }

    // ADMIN FUNCTIONALITY
    function setGateway(string memory gatewayURI) public ownerOnly {
        _currentGatewayURI = gatewayURI;
    }

    /**
     * @dev Transfers ownership
     * @param _newOwner The new owner
     */
    function transferOwnership(address _newOwner) public ownerOnly {
        ownerAddress = _newOwner;
    }

    function setPresaleStatus(bool ps) public ownerOnly {
        preSaleStatus = ps;
    }

    function setMainsaleStatus(bool ms) public ownerOnly {
        mainSaleStatus = ms;
    }

    function setMintPrice(uint256 mp) public ownerOnly {
        mintPrice = mp;
    }

    function setMaxItemsPerTx(uint256 _maxItemsPerTx) external ownerOnly {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setMaxItemsPerPreSale(uint256 _maxItemsPerPreSale)
        external
        ownerOnly
    {
        maxItemsPerPreSale = _maxItemsPerPreSale;
    }

    function addToWhitelist(address[] memory toAdd) external ownerOnly {
        for (uint256 i = 0; i < toAdd.length; i++) {
            preMints[toAdd[i]] = maxItemsPerPreSale;
        }
    }

    function setAdoptions(uint256[] memory adoptions) external ownerOnly {
        for (uint256 i = 0; i < adoptions.length; i++) {
            tokenAdoption[i + 1] = adoptions[i];
            staticTokenAdoption[i + 1] = adoptions[i];
        }
    }

    function setBaseURI(string memory baseURI) external ownerOnly {
        _currentBaseURI = baseURI;
    }

    function addToOg(address[] memory toAdd, uint256[] memory pick)
        external
        ownerOnly
    {
        for (uint256 i = 0; i < toAdd.length; i++) {
            Ogs[pick[i]] = toAdd[i];
            addressExist[pick[i]] = true;
            // preMints[toAdd[i]] = maxItemsPerPreMint;
        }
    }

    function ogbulkMint(uint256[] memory pick) external {
        for (uint256 i = 0; i < pick.length; i++) {
            require(
                pick[i] <= 100 && pick[i] > 0,
                "Error: Maximum number of tokens have been minted"
            );
            _ogmintToken(pick[i]);
        }
    }

    function ogsingleMint(uint256 pick) external {
        require(
            pick <= 100 && pick > 0,
            "Error: Maximum number of tokens have been minted"
        );
        _ogmintToken(pick);
    }

    modifier ownerOnly() {
        require(msg.sender == ownerAddress, "Error: Action Not Allowed");
        _;
    }

    //Internal

    function _ogmintToken(uint256 pick) private returns (uint256) {
        //Check if token has been minted
        require(!_exists(pick), "Mint for existing tokenId");
        require(
            pick <= 100 && pick > 0,
            "Error: Maximum number of tokens have been minted"
        );
        //check if address exist
        require(addressExist[pick], "No address available for token");
        address recipient = Ogs[pick];
        // Mint token to PickOwner
        genesisAddress[pick] = recipient;
        _safeMint(recipient, pick);
        giraffes[pick] = Giraffe(block.timestamp);
        tokenRound[pick] = 0;
        return pick;
    }

    function getOgs() public view returns (address[] memory) {
        address[] memory ogs = new address[](101);
        for (uint256 i = 0; i <= 100; i++) {
            ogs[i] = Ogs[i];
        }
        return ogs;
    }

    function getGenesisAddresses() public view returns (address[] memory) {
        address[] memory ga = new address[](10001);
        for (uint256 i = 0; i <= 10000; i++) {
            ga[i] = genesisAddress[i];
        }
        return ga;
    }

    function getGenesisAddress(uint256 token_id) public view returns (address) {
        return genesisAddress[token_id];
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function rewardBalance(uint256 tokenId) public view returns (uint256) {
        //    require(ownerOf(tokenId) == msg.sender && tokenId < 100 , "WR:Invalid");
        uint256 total = (totalDividends - tokenRound[tokenId]) / OgsCount;
        return total;
    }

    function adoptionsOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenAdoption[tokenOfOwnerByIndex(_owner, i)];
        }
        return tokensId;
    }

    function withdrawFunds(uint256 amount) public ownerOnly {
        sendEth(ownerAddress, amount);
    }

    function sendEth(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function withdrawToken(
        IERC20 token,
        address recipient,
        uint256 amount
    ) public ownerOnly {
        require(
            token.balanceOf(address(this)) >= amount,
            "You do not have sufficient Balance"
        );
        token.transfer(recipient, amount);
    }
}