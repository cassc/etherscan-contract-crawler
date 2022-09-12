pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Hulki is ERC721URIStorage, Ownable { 
    /** @notice token uris and price per token */
    string private startURI = "";
    uint256 public price;

    /** @notice rounds from 0 to 4 */
    uint8 public round;

    /** @notice approved managers, such as staking contract */
    mapping(address => bool) public approved;

    /** @notice counters for nft ids */
    uint256 bannerId = 0;
    uint256 beastId = 1000;
    uint256 warId = 1800;
    uint256 battleId = 2400;
    uint256 valhallaId = 2800;
    uint256 cap = 3000;

    /** @notice token id => its evolution */
    mapping (uint256 => uint256) public tokenByEvo;

    constructor() ERC721("HULKI", "HULKI") {
        approved[msg.sender] = true;
    }

    /**
     * @notice public mint function
     * @param _mode => 0.called from staking contract
     * 1.multipack mint
     * @param _amount => amount of nfts to mint
     * @param _evo => evolution of nft
     * @param _tokenId => token to burn. in case evolution
     * is chosen as a mint option.
     */
    function mint(
        uint8 _mode,
        uint8 _amount,
        uint8 _evo,
        uint256 _tokenId,
        address _to
    ) public payable {
        if (_mode == 0) {
            require(approved[msg.sender], "msg.sender is not approved");
            evolve(_evo, _tokenId, _to);
        } else if (_mode == 1) {
            require(msg.value >= price * _amount, "Price not paid");
            if (round == 0) {
                require(_amount + bannerId <= 200, "Cant exceed supply");
                _lowMint(0, _amount, msg.sender, false);
                if (_amount >= 5 && _amount < 10) {
                    require(1 + beastId <= 1200, "Cant exceed supply");
                    _lowMint(1, 1, msg.sender, false);
                } else if (_amount >= 10 && _amount < 15) {
                    require(1 + warId <= 2000, "Cant exceed supply");
                    _lowMint(2, 1, msg.sender, false);
                } else if (_amount >= 15 && _amount < 20) {
                    require(1 + battleId <= 2600, "Cant exceed supply");
                    _lowMint(3, 1, msg.sender, false);
                } else if (_amount >= 20) {
                    require(1 + valhallaId <= 3000, "Cant exceed supply");
                    _lowMint(4, 1, msg.sender, false);
                }
            } else if (round == 1) {
                require(_amount + bannerId <= 400, "Cant exceed supply");
                _lowMint(0, _amount, msg.sender, false);
                if (_amount >= 5 && _amount < 10) {
                    require(1 + beastId <= 1400, "Cant exceed supply");
                    _lowMint(1, 1, msg.sender, false);
                } else if (_amount >= 10 && _amount < 15) {
                    require(1 + warId <= 2200, "Cant exceed supply");
                    _lowMint(2, 1, msg.sender, false);
                } else if (_amount >= 15) {
                    require(1 + battleId <= 2800, "Cant exceed supply");
                    _lowMint(3, 1, msg.sender, false);
                }
            } else if (round == 2) {
                require(_amount + bannerId <= 600, "Cant exceed supply");
                _lowMint(0, _amount, msg.sender, false);
                if (_amount >= 5 && _amount < 10) {
                    require(1 + beastId <= 1600, "Cant exceed supply");
                    _lowMint(1, 1, msg.sender, false);
                } else if (_amount >= 10) {
                    require(1 + warId <= 2400, "Cant exceed supply");
                    _lowMint(2, 1, msg.sender, false);
                }
            } else if (round == 3) {
                require(_amount + bannerId <= 800, "Cant exceed supply");
                _lowMint(0, _amount, msg.sender, false);
                if (_amount >= 5) {
                    require(1 + beastId <= 1800, "Cant exceed supply");
                    _lowMint(1, 1, msg.sender, false);
                }
            } else if (round == 4) {
                require(_amount + bannerId <= 1000, "Cant exceed supply");
                _lowMint(0, _amount, msg.sender, true);
            }
        }
    }

    /**
     * @notice evolution is a process of sending lower evo tokens
     * and in exchange getting higher evo token. Called by staking
     * contract.
     * @param _evo => level of evolution
     * @param _tokenId => id of token to burn
     * @param _to => "msg.sender"
     */
    function evolve(
        uint8 _evo,
        uint256 _tokenId,
        address _to
    ) internal {
        _burn(_tokenId);
        if (_evo != 4) {
            _lowMint(_evo + 1, 1, _to, false);
        } else {
            revert("Cant evolve valhalla");
        }
    }

    /**
     * @notice internal mint function for cleaner code
     * @param _evo => stands for evolution of nft
     * @param _amount => amount of nfts to mint
     *
     * since we have multiple tiers of tokens, we need to set
     * separate tokenURIs for each. using openzeppelin library,
     * during the mint each token will get their own custom URI.
     */
    function _lowMint(
        uint8 _evo,
        uint256 _amount,
        address _to,
        bool _lastRound
    ) internal {
        if (_evo == 0) {
            for (uint256 x; x < _amount; x++) {
                bannerId++;
                _safeMint(_to, bannerId);
                _setTokenURI(
                    bannerId,
                    string(abi.encodePacked(startURI, "banner"))
                );

                if (_lastRound) {
                    tokenByEvo[bannerId] = 4;
                }
            }
        } else if (_evo == 1) {
            for (uint256 x; x < _amount; x++) {
                beastId++;
                _safeMint(_to, beastId);
                _setTokenURI(
                    beastId,
                    string(abi.encodePacked(startURI, "beast"))
                );
                tokenByEvo[beastId] = 0;
            }
        } else if (_evo == 2) {
            for (uint256 x; x < _amount; x++) {
                warId++;
                _safeMint(_to, warId);
                _setTokenURI(warId, string(abi.encodePacked(startURI, "war")));
                tokenByEvo[warId] = 1;
            }
        } else if (_evo == 3) {
            for (uint256 x; x < _amount; x++) {
                battleId++;
                _safeMint(_to, battleId);
                _setTokenURI(
                    battleId,
                    string(abi.encodePacked(startURI, "battle"))
                );
                tokenByEvo[battleId] = 2;
            }
        } else if (_evo == 4) {
            for (uint256 x; x < _amount; x++) {
                valhallaId++;
                _safeMint(_to, valhallaId);
                _setTokenURI(
                    valhallaId,
                    string(abi.encodePacked(startURI, "valhalla"))
                );
                tokenByEvo[valhallaId] = 3;
            }
        } else {
            revert("Wrong _evo");
        }
    }

    /**
     * @notice manage approved members. should be handled with care
     * @param _user => address of manager
     * @param _state => remove or add them
     */
    function setApproved(address _user, bool _state) public onlyOwner {
        approved[_user] = _state;
    }

    /**
     * @notice set info about uris and price
     * @param _startURI => start of the token uri
     * @param _price => price per token * (10**18)
     */
    function setHulkiInfo(
        string memory _startURI,
        uint256 _price
    ) public onlyOwner {
        startURI = _startURI;
        price = _price;
    }

    /**
     * @notice set minting round, 0 to 4 (1 to 5)
     * @param _round => 0 to 4 (1 to 5)
     */
    function setRound(uint8 _round) public onlyOwner {
        require(_round <= 4, "Wrong round");
        round = _round;
    }

    /**
    * @notice get token id evolution
    * @param _tokenId => id of given NFT 
    * @return tokenByEvo => evolution level of given NFT
     */
    function getTokenEvo(uint256 _tokenId) public view returns (uint256) {
        return tokenByEvo[_tokenId];
    } 

    /**
    * @notice withdraw eth
     */
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}