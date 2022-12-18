import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract AltarHelper {
    function external_getWalletOfOwnerGenerativeGenesis(
        address address_,
        IERC721Upgradeable genesis,
        IERC721Upgradeable generative
    ) public view returns (uint256[] memory) {
        // For this function, we want to return a unified index
        uint256 _genesisBalance = genesis.balanceOf(address_);
        uint256 _generativeBalance = generative.balanceOf(address_);
        uint256 _totalBalance = _genesisBalance + _generativeBalance;

        // Create the indexes based on a combined balance to input datas
        uint256[] memory _indexes = new uint256[](_totalBalance);

        // Call both wallet of owners
        uint256[] memory _walletOfGenesis = walletOfGenesis(address_, genesis);
        uint256[] memory _walletOfGenerative = walletOfGenerative(address_, generative);

        // Now start inserting into the index with both wallets with offsets
        uint256 _currentIndex;
        for (uint256 i = 0; i < _walletOfGenerative.length; i++) {
            // Generative has an offset of 0
            _indexes[_currentIndex++] = _walletOfGenerative[i];
        }
        for (uint256 i = 0; i < _walletOfGenesis.length; i++) {
            // Genesis has an offset of 10000
            _indexes[_currentIndex++] = _walletOfGenesis[i] + 10000;
        }

        return _indexes;
    }

    function walletOfGenesis(address address_, IERC721Upgradeable genesis) public view returns (uint256[] memory) {
        (bool success, bytes memory data) = address(genesis).staticcall(
            abi.encodeWithSignature("walletOfOwner(address)", address_)
        );
        return abi.decode(data, (uint256[]));
    }

    function walletOfGenerative(
        address address_,
        IERC721Upgradeable generative
    ) public view returns (uint256[] memory) {
        (bool success, bytes memory data) = address(generative).staticcall(
            abi.encodeWithSignature("walletOfOwner(address)", address_)
        );
        return abi.decode(data, (uint256[]));
    }
}