// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// ERC721A v4
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Iashes {
    function transfer(address to_, uint256 amount_) external returns (bool);

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external returns (bool);

    function mint(address to_, uint256 amount_) external;

    function burn(address from_, uint256 amount) external;

    function balanceOf(address user) external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface Ibagic {
    function transfer(address to_, uint256 amount_) external returns (bool);

    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external returns (bool);

    function mint(address to_, uint256 amount_) external;

    function burn(address from_, uint256 amount) external;

    function balanceOf(address user) external view returns (uint256);

    function decimals() external view returns (uint8);
}

interface IPattern {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Banbook is ERC721AQueryable, Ownable {
/*
                                                                   ,▄▓█
                      ,░░░,                      ,¿░░,         ,╓▄▓▓▓▓▓▓▀
                   ,▒░░░░░░░▒,                ,∩▒░░░░░░▒,  ,▄▓▓▓▓▓▓▓▓▓▓`
                 ╓▒░░░░░░░░░░░░▒,          ,∩▒░░░░░░░░░░╓▓▓▓▓▓▓▓▓▓▓▓▓"
               q▒░░░░░░░░░░░░░░░░▒╖      ╓▒▒░░░░░░░░░░@▓▓▓▓▓▓██▓▓▓▀
              ,╫▓▓@░░░░░░░░░░░░░▒▒▒╢N  ╔╣▒▒▒▒░░░░░░░g▓▓▓▓▓▓█▓▓▓▓`
              ╟@Φ╖▒▀▓▓▄░░░░░░░░░▒▒▒╢╢▓╫╣▒▒▒▒▒░░░░░░▓▓▓▓▓▓█▓▓▓▓╣,
             ╩░░░╙▓▓▓▓▄▓▀▓▄░░░░▒▒▒▒╢╢▓╣╢╣▒▒▒▒▒░░░░▓▓▓▓▓██▓▓▓▓▓▓
            ,╙╨▓▓▓▓▓▓▄▄⌠▀▀▓▓▓w░▒▒▒╣╢╫▓▓╣╣▒▒▒▒▒▒▒M╟▓▓▓▓█▓▓▓▓▒▒▒▒w∩
           ╩▓▓▓▓▓▓φ@╥▄▄║▀▀▀ÑW▓▓▓▒▒╢╢▓▓▓▓╣╣▒▒▒▒▄M▀▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╜
          ,@@@▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╣╣▒▓▓╢▓▓▓▓╣╣▒▒▒Ñ╣▓▓▓▓▓▓▓▓▓[email protected]@@@@╦╦─
         ,g▓╝╩╨▀▀▀▓▓▓▒▒╬╫▓▓▓▓▓▓▓▓▓╢╫▓▓▓▓╣╣▓▒▓▓▓▓╬▓▓▓▓▓╫▓▓▓▓▓▓▓▓▓╬╣╖
        ▒▓█▄▓▓▓▓▓▓▓▓█████████████████▓▓▓███▄▄▄▄▓█▄▄▄▄▄▄▄▄▄▓▓▄▄▄▄▄██╣▒
*/
    string private _baseTokenURI;

    bool public isMintActive = false;
    uint256 public maxSupply = 10000;
    uint256 public price = 0.01 ether;

    mapping(uint256 => uint256) public banbookMaxPages;
    mapping(uint256 => uint256) public banbookPages;

    mapping(address => uint256) public banCount;

    Iashes public ASH;
    Ibagic public BG;
    IPattern public PATT;

    mapping(address => uint256) public stakedAshes;
    mapping(address => uint256) public stakedAshesTimeStamps;

    mapping(uint256 => bool) public claimedPattern;

    mapping(address => uint256) public lastUnbanBlockNo;

    event Ban(
        address indexed from,
        address indexed target,
        uint256 indexed banCount
    );
    event Unban(
        address indexed from,
        address indexed target,
        uint256 indexed banCount
    );

    constructor(
        address ashesAddress,
        address bagicAddress,
        address patternAddress
    ) ERC721A("Banbook", "BBK") {
        ASH = Iashes(ashesAddress);
        BG = Ibagic(bagicAddress);
        PATT = IPattern(patternAddress);
    }

    function pickItUpFromTheFloor(uint256 quantity) external payable {
        require(isMintActive, "mint inactive");
        require(msg.value >= quantity * price, "not enough ETH");
        require(totalSupply() + quantity <= maxSupply, "reached max supply");

        _openBanbook(quantity);
    }

    function pickItUpFromThePattern(uint256 tokenId) external {
        require(PATT.ownerOf(tokenId) == msg.sender, "not token owner");
        require(claimedPattern[tokenId] == false, "already claimed");
        require(totalSupply() + 8 <= maxSupply, "reached max supply");

        claimedPattern[tokenId] = true;
		if (tokenId < 51){
        _openBanbook(8);
		}else{
		require(isMintActive, "mint inactive");
		_openBanbook(2);
		}
    }

    function pickItUpFromTheSky(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        _openBanbook(quantity);
    }

    function _openBanbook(uint256 quantity) internal {
		uint256 _lifeReserved = 0;
        for (uint256 i = 0; i < quantity; i++) {
            uint256 _life = (uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        msg.value,
                        totalSupply(),
                        i,
                        gasleft(),
                        tx.gasprice,
                        block.difficulty,
                        block.coinbase
                    )
                )
            ) % 1048576) + 16384; // 1.5625%
			uint256 _lifeReduced = _life * 100000000 / 1000000000;
			_lifeReserved += _lifeReduced;
            banbookMaxPages[totalSupply() + i] = _life;
            banbookPages[totalSupply() + i] = _life - _lifeReduced;
        }
		BG.mint(owner(), _lifeReserved * (10**uint256(BG.decimals())));
        _safeMint(msg.sender, quantity);
    }

    // banUnban
    function cast(address target, uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not token owner");
        require(banCount[target] < 19, "reached max banCount");
        require(
            target == msg.sender || banCount[msg.sender] % 2 == 0,
            "sender is being banned!"
        );
        require(
            target == msg.sender || lastUnbanBlockNo[msg.sender] < block.number,
            "cannot cast after unban yourself in the same block"
        );

        // same cost to ban and unban
        // increse by power of 4 after each banUnban/cast
        uint256 cost = 4**(banCount[target] / 2);
        // overflow error if not enough book life
        banbookPages[tokenId] -= cost;

        uint256 _banCount = banCount[target] + 1;
        banCount[target] = _banCount;

        // convert to ashes
        ASH.mint(msg.sender, cost * (10**uint256(ASH.decimals())));

        if (banCount[target] % 2 == 1) {
            emit Ban(msg.sender, target, _banCount);
        } else {
            if (target == msg.sender) {
                lastUnbanBlockNo[msg.sender] = block.number;
            }
            emit Unban(msg.sender, target, _banCount);
        }
    }

    // cannot transfer if the address is being banned
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721A) {
        require(banCount[from] % 2 == 0, "sender is being banned!");
        require(banCount[to] % 2 == 0, "receiver is being banned!");
        super.transferFrom(from, to, tokenId);
    }

    // stakeAshes
    function charge(uint256 quantity) external {
        alter();
        ASH.transferFrom(msg.sender, address(this), quantity);
        stakedAshes[msg.sender] += quantity;
    }

    // unstakeAshes
    function discharge(uint256 quantity) external {
        alter();
        stakedAshes[msg.sender] -= quantity;
        ASH.transfer(msg.sender, quantity);
    }

    // claim, transform Ashes to Bagic
    function alter() public {
        uint256 claimAmount = (stakedAshes[msg.sender] *
            (block.timestamp - stakedAshesTimeStamps[msg.sender])) / 3 days;

        stakedAshes[msg.sender] -= claimAmount;
        stakedAshesTimeStamps[msg.sender] = block.timestamp;

        ASH.burn(address(this), claimAmount);
        BG.mint(msg.sender, claimAmount);
    }

    // forge pages using Bagic
    function forge(uint256 tokenId, uint256 quantity) public {
        BG.burn(msg.sender, quantity * (10**uint256(BG.decimals())));
        banbookPages[tokenId] += quantity;
        require(
            banbookMaxPages[tokenId] >= banbookPages[tokenId],
            "reached max life"
        );
    }

    // lowerBanCount
    function pardon(address target, uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "not token owner");

        uint256 cost = 4**(banCount[target] / 2 + 1);
        // overflow error if not enough book life
        banbookPages[tokenId] -= cost;

        // underflow error if banCount = 0
        banCount[target] -= 2;

        // convert to ashes
        ASH.mint(msg.sender, cost * (10**uint256(ASH.decimals())));
    }

    function setIsMintActive(bool _isActive) external onlyOwner {
        isMintActive = _isActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "transfer failed");
    }
}