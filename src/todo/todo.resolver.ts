import { Resolver, Query, Mutation } from '@nestjs/graphql';
import { Todo } from './entity/todo.entity';

@Resolver()
export class TodoResolver {

    @Query( () => [Todo], {name: 'todos'})
    findAll(): [Todo] {
        return [{ id: 212, description: 'Este es un todo', done: false}]
    }

    // @Query(() => [{toDo: String}])
    findOne() {

    }

    // @Mutation()
    createToDo() {
    
    } 
    // @Mutation()
    updateToDo() {

    }

    // @Mutation()
    removeToDo() {

    }
}
