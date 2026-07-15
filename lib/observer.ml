type 'a t = { node : 'a Node.t }

let observe ?name:_ node = { node }
let value t = Node.get t.node
let node t = t.node
