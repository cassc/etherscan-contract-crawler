// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

Genesis2052Passport.sol

Written by: mousedev.eth

*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Genesis2052Passport is ERC721, Ownable {
    using Strings for uint256;

    address public signer;
    string public baseURI;
    string public contractURI;
    uint256 public nextTokenId = 1;

    mapping(address => bool) public walletHasMinted;

    //EIP2981
    uint256 private _royaltyBps;
    address private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;

    //Custom errors
    error MaxSupplyExceeded();
    error WalletAlreadyMinted();
    error SignatureNotValid();

    constructor() ERC721("Genesis 2052 Passport", "205Z") {}

    /*

   __  __                  ______                 __  _
  / / / /_______  _____   / ____/_  ______  _____/ /_(_)___  ____  _____
 / / / / ___/ _ \/ ___/  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
/ /_/ (__  )  __/ /     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
\____/____/\___/_/     /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/


*/

    function mintPassport(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (nextTokenId > 1111) revert MaxSupplyExceeded();
        if (walletHasMinted[msg.sender]) revert WalletAlreadyMinted();
        if (
            verifyHash(keccak256(abi.encodePacked(msg.sender)), v, r, s) !=
            signer
        ) revert SignatureNotValid();

        //Mark minted before minting.
        walletHasMinted[msg.sender] = true;
        _mint(msg.sender, nextTokenId);

        unchecked {
            ++nextTokenId;
        }
    }

    /*

    _____   __________________  _   _____    __       ________  ___   ______________________  _   _______
   /  _/ | / /_  __/ ____/ __ \/ | / /   |  / /      / ____/ / / / | / / ____/_  __/  _/ __ \/ | / / ___/
   / //  |/ / / / / __/ / /_/ /  |/ / /| | / /      / /_  / / / /  |/ / /     / /  / // / / /  |/ /\__ \
 _/ // /|  / / / / /___/ _, _/ /|  / ___ |/ /___   / __/ / /_/ / /|  / /___  / / _/ // /_/ / /|  /___/ /
/___/_/ |_/ /_/ /_____/_/ |_/_/ |_/_/  |_/_____/  /_/    \____/_/ |_/\____/ /_/ /___/\____/_/ |_//____/


*/

    function verifyHash(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        return ecrecover(messageDigest, v, r, s);
    }

    /*
 _    ___                 ______                 __  _
| |  / (_)__ _      __   / ____/_  ______  _____/ /_(_)___  ____  _____
| | / / / _ \ | /| / /  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
| |/ / /  __/ |/ |/ /  / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
|___/_/\___/|__/|__/  /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

*/

    function walletOfOwner(address _address)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        //Thanks 0xinuarashi for da inspo

        uint256 _balance = balanceOf(_address);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _addedTokens;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (ownerOf(i) == _address) {
                _tokens[_addedTokens] = i;
                _addedTokens++;
                }

            if (_addedTokens == _balance) break;
        }
        return _tokens;
    }

    function totalSupply() public view returns (uint256) {
        return nextTokenId - 1;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist!");
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981;
    }

    function royaltyInfo(uint256, uint256 value)
        external
        view
        returns (address, uint256)
    {
        return (_royaltyRecipient, (value * _royaltyBps) / 10000);
    }

    /*
   ____                              ______                 __  _
  / __ \_      ______  ___  _____   / ____/_  ______  _____/ /_(_)___  ____  _____
 / / / / | /| / / __ \/ _ \/ ___/  / /_  / / / / __ \/ ___/ __/ / __ \/ __ \/ ___/
/ /_/ /| |/ |/ / / / /  __/ /     / __/ / /_/ / / / / /__/ /_/ / /_/ / / / (__  )
\____/ |__/|__/_/ /_/\___/_/     /_/    \__,_/_/ /_/\___/\__/_/\____/_/ /_/____/

*/

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setContractURI(string calldata _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function updateRoyalties(address payable recipient, uint256 bps)
        external
        onlyOwner
    {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }
}