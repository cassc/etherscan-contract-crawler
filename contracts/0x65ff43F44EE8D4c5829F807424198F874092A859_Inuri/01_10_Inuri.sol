// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Inuri is ERC721AQueryable, Ownable, DefaultOperatorFilterer {
    enum CurrentState {
        PAUSE,
        WL,
        PUB
    }

    constructor(string memory tokenUri) ERC721A("Inuri", "INR") {
        baseTokenURI = tokenUri;
    }

    uint256 public constant maxSupply = 444;
    uint256 public constant freeSupply = 222;


    uint256 public constant maxWalletMintWL = 1;
    uint256 public constant maxWalletMintPub = 3;
    uint256 public price = 0.009 ether;


    bool public stakeOpen;
    uint256 public totalStaked;
    mapping(address => uint256) private balances;
    mapping(uint256 => address) private assets;

    string public baseTokenURI;
    CurrentState public state;

    function addWhitelist(address[] calldata addresses, CurrentState status) external onlyOwner {
        for (uint256 i; i < addresses.length; ) {
            _setAux(addresses[i], uint64(status));
            unchecked {
                i++;
            }
        }
    }

    function adminMint(uint256 amount, address to) external onlyOwner {
        require(amount + totalSupply() <= maxSupply);
        _safeMint(to, amount);
    }

    function sellSoul() external payable {
        require(state == CurrentState.WL, "Portal is close");

        require(_getAux(msg.sender) == uint64(CurrentState.WL), "You can't enter to portal");
        require(totalSupply() + 1 <= maxSupply, "Portal is full");
        if (totalSupply() + 1 >= freeSupply) {
            require(msg.value >= price, "Pay more to enter portal");
        }
        require(_numberMinted(msg.sender) + 1 <= maxWalletMintWL, "You are already in portal");

        _mint(msg.sender, 1);
    }

    function sellSoulPublic(uint256 amount) external payable {
        require(state == CurrentState.PUB, "Portal open only for homies now");
        require(totalSupply() + amount <= maxSupply, "Portal is full");
        require(msg.sender == tx.origin, "Portal doesn't accept cheaters");
        if (totalSupply() + 1 >= freeSupply) {
            require(msg.value >= amount * price, "Pay more to enter portal");
        }
        require(_numberMinted(msg.sender) + amount <= maxWalletMintPub, "You are already in portal");

        _safeMint(msg.sender, amount);
    }

    function openPortal(CurrentState newState) external onlyOwner {
        state = newState;
    }

    function changePortalTicketPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function stake(uint256 tokenId)
        public
    {
        require(stakeOpen, "Staking not open");
        assets[tokenId] = _msgSender();

        balances[_msgSender()] += 1;

        totalStaked += 1;

        this.safeTransferFrom(_msgSender(), address(this), tokenId);

        emit Staked(_msgSender(), tokenId);
    }

    function withdrawFromStaking(uint256 tokenId)
        public
    {
        require(assets[tokenId] == _msgSender(), "You are not the staker");

        assets[tokenId] = address(0);

        balances[_msgSender()] -= 1;
        
        totalStaked -= 1;

        this.safeTransferFrom(address(this), _msgSender(), tokenId);

        emit Withdrawn(_msgSender(), tokenId);
    }

    function setStakingStatus(bool status)
        external
        onlyOwner
    {
        stakeOpen = status;
    }


    function ownerBurn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Failed to withdraw Ether");
    }

    function yourPhase(address yourAddress) public view returns (uint256) {
        return _getAux(yourAddress);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    event Staked(address indexed staker, uint256 indexed tokenId);
    event Withdrawn(address indexed staker, uint256 indexed tokenId);
}