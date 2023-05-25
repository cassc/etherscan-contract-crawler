// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.3/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.3/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.3/contracts/token/ERC20/IERC20.sol";
import "https://github.com/Brechtpd/base64/blob/main/base64.sol";

contract TWNFT is ERC721Enumerable, Ownable {
    //This token address will be checked if enough tokens are available
    address public requireTokenAddress;

    //After this date, public minting of soldiers will be possible. Before this date, only the owner and generals can be minted.
    uint256 private constant START_TIMESTAMP = 1633521600; //06.10.2021, 12:00 GMT (14:00 CEST)

    //the address that minted an NFT cannot mint it again. You would need to send your tokens to another address to mint again
    mapping(address => bool) addressMinted;
    //for investors, we can whitelist addresses in order they can mint generals
    mapping(address => bool) whitelist;

    string private constant COMMANDER = "bafybeick7bj677i3fhq5upoc2vplu4gmgmgdpacbtahx6f4uqkgl7dattq"; //rank 1
    string private constant GENERAL   = "bafybeidzfegfpn24lpjkf235tdhqvk26b2bsr7ye7sj2ggsodxk4rs25ju"; //rank 2
    string private constant SOLDIER   = "bafybeiceynivdpcrnu633gmcyp36x4lw7avehpznbjx5i62a52nqh2lk5i"; //rank 3
    string private constant ARMY      = "bafybeihn4y3bf364ihww2ogzpqavuryhjaeakvpk6ci7rrkjj4mmsqjpae"; //image for platform

    uint256 private constant COMMANDER_MINT = 5000000 * 1e18;  //5,000,000 x 10^18
    uint256 private constant GENERAL_MINT   = 500000  * 1e18;  //  500,000 x 10^18
    uint256 private constant SOLDIER_MINT   = 1000    * 1e18;  //    1,000 x 10^18

    uint256 private constant FIRST_COMMANDER_ID   = 1;
    uint256 private constant FIRST_GENERAL_ID     = 21;
    uint256 private constant FIRST_DEV_SOLDIER_ID = 221;
    uint256 private constant FIRST_PUB_SOLDIER_ID = 421;
    uint256 private constant FIRST_INVALID        = 2221;

    uint256 private nextCommanderId  = FIRST_COMMANDER_ID;   //  1-20
    uint256 private nextGeneralId    = FIRST_GENERAL_ID;     // 21-220
    uint256 private nextDevSoldierId = FIRST_DEV_SOLDIER_ID; //221-420
    uint256 private nextPubSoldierId = FIRST_PUB_SOLDIER_ID; //421-2220

    bool public releasedTGT;

    string private constant datajson = "data:application/json;base64,";
    string private baseURI = "ipfs://";
    string private description = "THORWallet NFTs consist of 20 Commanders, 200 Generals and 2000 Soldiers that unlock unique premium features in the THORWallet.";

    constructor() ERC721("THORWallet Army", "TWA"){}

    //This is for external application to know the current supply of the ranks
    //1: the number of commanders minted. If one commander is added, nextCommanderId will be set to 2, while FIRST_COMMANDER_ID is 1, hence 1
    //2: the number of generals minted. If one general is added nextGeneralId will be set to 22, while FIRST_GENERAL_ID is 21, hence 1
    //3: the number of dev and pub soldiers. If one dev soldier will be added nextDevSoldierId, will be 222, FIRST_DEV_SOLDIER_ID is 221, hence 1
    //here we need to add the pub soldier: if one pub soldier will be added nextPubSoldierId, will be 422, FIRST_PUB_SOLDIER_ID is 421, hence 1
    function currentSupply(uint256 _rank) public view returns (uint256) {
        if (_rank == 1) {
            return nextCommanderId - FIRST_COMMANDER_ID;
        } else if (_rank == 2) {
            return nextGeneralId - FIRST_GENERAL_ID;
        } else if (_rank == 3) {
            return (nextDevSoldierId - FIRST_DEV_SOLDIER_ID) + (nextPubSoldierId - FIRST_PUB_SOLDIER_ID);
        } else {
            revert("currentSupply: invalid rank");
        }
    }

    //This is for external application to know the max supply
    //Not to be confused with totalSupply, which is the number of minted NFTs
    function maxSupply() public pure returns (uint256) {
        return FIRST_INVALID - 1;
    }

    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public {
        for (uint256 i = 0; i < addrs.length; i++) {
            whitelist[addrs[i]] = true;
        }
    }

    function removeAddressFromWhitelist(address addr) onlyOwner public {
        whitelist[addr] = false;
    }

    function whitelisted(address _address) public view returns (bool) {
        return whitelist[_address];
    }

    function minted(address _address) public view returns (bool) {
        return addressMinted[_address];
    }

    function setBaseURI(string calldata _baseURI) onlyOwner public {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        string memory rank;
        string memory rankImage;

        if (tokenId < FIRST_GENERAL_ID) {
            rank = "Commander";
            rankImage = COMMANDER;
        } else if (tokenId < FIRST_DEV_SOLDIER_ID) {
            rank = "General";
            rankImage = GENERAL;
        } else {
            rank = "Soldier";
            rankImage = SOLDIER;
        }

        return string(
            abi.encodePacked(
                datajson,
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"THORWallet - ',
                            rank,
                            '","description":"',
                            description,
                            '","attributes":[{"trait_type": "Rank", "value": "',
                            rank,
                            '"}], "image":"',
                            baseURI,
                            rankImage,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function getLevel(address _address) public view returns (uint256) {
        //Levels: 0=None, 1=Commander, 2=General, 3=Soldier
        uint256 addressBalance = balanceOf(_address);

        if (addressBalance == 0) {
            return 0;               //No NFT held
        }

        uint256 lowest = tokenOfOwnerByIndex(_address, 0);
        uint256 id;

        for (uint256 i=0; i < addressBalance; i++) {
            id = tokenOfOwnerByIndex(_address, i);
            if(id < lowest) {
                lowest = id;
            }
        }

        if (lowest >= FIRST_DEV_SOLDIER_ID) {
            return 3;               // Soldier TokenId 221-2220 -> 2000 Soldiers
        } else if (lowest >= FIRST_GENERAL_ID) {
            return 2;               // General TokenId 21-220 -> 200 Generals
        } else {
            return 1;               // Commander TokenId 1-20 -> 20 Commanders
        }
    }

    function setRequiredToken(address _tokenAddress) public onlyOwner {
        requireTokenAddress = _tokenAddress;
    }

    function setReleasedTGT(bool _released) public onlyOwner {
        releasedTGT = _released;
    }

    //used for external projects, e.g., https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return string(
            abi.encodePacked(
                datajson, Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "THORWallet Army", "description": "',
                            description,
                            '", "image": "',
                            baseURI,
                            ARMY,
                            '", "external_link": "https://thorwallet.org"}'
                        )
                    )
                )
            )
        );
    }

    function mintWhitelisted() public {
        require(whitelist[msg.sender], "Address not Whitelisted");
        require(!addressMinted[msg.sender], "Prior mint by address");
        //check if General limt reached, if we are already at the first dev soldier
        require(nextGeneralId < FIRST_DEV_SOLDIER_ID, "General limit reached");

        uint256 tokenId = nextGeneralId;
        nextGeneralId = nextGeneralId + 1;

        _safeMint(msg.sender, tokenId);

        //add msg.sender to list of minters, who already minted (they cannot mint twice)
        addressMinted[msg.sender] = true;
    }

    //mints multiple NFTs of same rank to provided addresses
    function mintByOwner(address[] memory _addresses, uint256 _rank) public onlyOwner {
        require(_addresses.length >= 1, "No addresses");

        uint256 tokenId;

        for (uint256 i=0; i < _addresses.length; i++) {
            if (_rank == 1) {
                //check if Commander limit reached, if we are already at the first general id
                require(nextCommanderId < FIRST_GENERAL_ID, "Commander limit reached");
                tokenId = nextCommanderId;
                nextCommanderId = nextCommanderId + 1;
            } else if (_rank == 2) {
                //check if General limit reached, if we are already at the first dev soldier
                require(nextGeneralId < FIRST_DEV_SOLDIER_ID, "General limit reached");
                tokenId = nextGeneralId;
                nextGeneralId = nextGeneralId + 1;
            } else if (_rank == 3) {
                //check if Dev Soldier limit reached, if we are already at the public soldier
                require(nextDevSoldierId < FIRST_PUB_SOLDIER_ID, "Dev Soldier limit reached");
                tokenId = nextDevSoldierId;
                nextDevSoldierId = nextDevSoldierId + 1;
            } else {
                revert("mintByOwner: invalid rank");
            }

            _safeMint(_addresses[i], tokenId);
        }
    }

    function mint() public {
        require(block.timestamp >= START_TIMESTAMP, "Claiming not yet started");
        //restricts minting address to 1 nft
        require(!addressMinted[msg.sender], "Prior mint by address");

        //check token quantity
        uint256 bal = IERC20(requireTokenAddress).balanceOf(msg.sender);
        //check if insufficient balance, if soldier level not reached
        require(bal >= SOLDIER_MINT , "Insufficient balance");

        uint256 tokenId;

        if (bal >= COMMANDER_MINT && releasedTGT) {
            //check if Commander limit reached, if we are already at the first general id
            require(nextCommanderId < FIRST_GENERAL_ID, "Commander limit reached");
            tokenId = nextCommanderId;
            nextCommanderId = nextCommanderId + 1;

        } else if (bal >= GENERAL_MINT && releasedTGT) {
            //check if General limit reached, if we are already at the first dev soldier
            require(nextGeneralId < FIRST_DEV_SOLDIER_ID, "General limit reached");
            tokenId = nextGeneralId;
            nextGeneralId = nextGeneralId + 1;

        } else {
            //check if Soldier limit reached, if we are already at the first invalid id
            require(nextPubSoldierId < FIRST_INVALID, "Soldier limit reached");
            tokenId = nextPubSoldierId;
            nextPubSoldierId = nextPubSoldierId + 1;
        }

        _safeMint(msg.sender, tokenId);

        //add msg.sender to list of minters, who already minted (they cannot mint twice)
        addressMinted[msg.sender] = true;
    }
}