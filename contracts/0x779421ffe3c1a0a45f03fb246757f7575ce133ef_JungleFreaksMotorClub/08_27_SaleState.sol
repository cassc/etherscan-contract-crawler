// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error NoActiveSale();
error IncorrectSaleType();
error AllSalesFinished();
error NoPausedSale();

abstract contract SaleState {
   enum State {
          NOT_STARTED, // 0
          ACTIVE, // 1
          PAUSED, // 2
          FINISHED // 3
      }

    struct Sale{
        State state;
        string saleType;
    }

    event StateOfSale(State _state);
    event TypeOfSale(string _saleType);
    event IsPaused(bool _paused);

    Sale private _sale = Sale({saleType: "None", state: State.NOT_STARTED});

    modifier whenSaleIsActive(string memory saleType) {
      if (_sale.state != State.ACTIVE) revert NoActiveSale();
      if (keccak256(bytes(_sale.saleType)) != keccak256(bytes(saleType))) revert IncorrectSaleType();
      _;
    }

    function _setSaleState(State state) internal {
      if (_sale.state == State.FINISHED) revert AllSalesFinished();
      
      _sale.state = state;
      
      if (state == State.FINISHED) {
        _sale.saleType = "Finished";
        emit TypeOfSale(_sale.saleType);
      }

      emit StateOfSale(_sale.state);
    }

    function _setSaleType(string memory saleType) internal {
      if (_sale.state == State.FINISHED) revert AllSalesFinished();
      
      _sale.saleType = saleType;
      _sale.state = State.NOT_STARTED;
      emit TypeOfSale(_sale.saleType);
    }

    function getSaleState() public view returns (State) {
      return _sale.state;

    }

    function getSaleType() public view returns (string memory) {
      return _sale.saleType;
    }

    function _pause() internal {
      if (_sale.state != State.ACTIVE) revert NoActiveSale();

      _sale.state = State.PAUSED;
      emit IsPaused(true);
    }

    function _unpause() internal {
      if (_sale.state != State.PAUSED) revert NoPausedSale();
      
      _sale.state = State.ACTIVE;
      emit IsPaused(false);
    }
}