enum OrderStatus {
  pending,     // Pendiente
  preparing,   // Preparando
  shipped,     // Enviado
  completed,   // Completado
  cancelled,   // Cancelado
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:   return "Pendiente";
      case OrderStatus.preparing: return "Preparando";
      case OrderStatus.shipped:   return "Enviado";
      case OrderStatus.completed: return "Completado";
      case OrderStatus.cancelled: return "Cancelado";
    }
  }

  int get sortIndex {
    switch (this) {
      case OrderStatus.pending: return 0;
      case OrderStatus.preparing: return 1;
      case OrderStatus.shipped: return 2;
      case OrderStatus.completed: return 3;
      case OrderStatus.cancelled: return 4;
    }
  }

  String get apiValue => name;
}

OrderStatus orderStatusFromApiValue(String? value) {
  if (value == null) return OrderStatus.pending;
  final normalized = value.toLowerCase();
  switch (normalized) {
    case 'pending':
    case 'pendiente':
      return OrderStatus.pending;
    case 'preparing':
    case 'preparando':
      return OrderStatus.preparing;
    case 'shipped':
    case 'enviado':
      return OrderStatus.shipped;
    case 'completed':
    case 'completado':
      return OrderStatus.completed;
    case 'cancelled':
    case 'canceled':
    case 'cancelado':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}
